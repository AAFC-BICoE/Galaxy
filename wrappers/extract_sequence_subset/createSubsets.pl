#!/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Bio::Index::Fasta;
use Bio::SeqIO;
use File::Find;
use Data::Dumper;

=head1 NAME

createSubset.pl

=head1 SYNOPSIS

Will filter out sequences based on either OTU numbers or taxonomy and write them to file either just as sequence ids or 
including the sequence information in a fasta file.

=head1 OPTIONS

	-d | --lcadir		input identification dir [will try to find fasta/idxfasta and otutable automatically]
	-f | --fasta		input fasta file with all the sequence information
	-x | --idxfasta		index fasta file created as part of the LCA workflow
	-m | --mapping		mapping file containing all the sequence belonging to an OTU (tab seperated)
	-b | --biomtab		otu table (classic tab seperated format) with lineages 
				only required if extracting based on taxonomy
	-o | --output		output file name

	-n | --otunbr		comma sperated list of otu numbers
	-t | --taxonomy		scientific name of sequences to pull regexp allowed [k__; p__; c__; ...]

	--ids-only		only pull the sequence ids of matched sequences
	--rep-seqs		only pull the representative sequences [DEFAULT: all sequences]
	--use-seqio		use the SeqIO module from BioPerl (slow) 
				will do this by default if idxfasta is specified (fastest)
				parsing the fasta file (normal)
	--create-index		create index in you current working directory to use 

=head1 DESCRIPTION

Takes a otu mapping file (tab seperated) and a fasta file or index fasta file. Depending on the format of
the file containing the sequences (fasta, index) the script will accordingly extract any sequence matching
to either the otu number or taxonomy. This script will not create an index automatically unless the index 
flag is specified. If an fasta file is supplied it will go through the fasta file once checking if each 
sequence was matched (should not be much slower than index unless the fasta file is really large). 
	
=cut

my $options ={};

GetOptions ($options,
		"help|h",
		"lcadir|d=s",
		"fasta|f=s",
		"idxfasta|x=s",
		"mapping|m=s",
		"biomtab|b=s",
		"output|o=s",
		"otunbr|n=s",
		"taxonomy|t=s",
		"create-index",
		"ids-only",
		"rep-seqs",
		"use-seqio",
	); 
if (defined $options->{'lcadir'}) { 
	# find fasta/idxfasta file and otu mapping file
	find({ wanted => \&get_files, follow => 1, follow_skip => 2, no_chdir => 1 }, $options->{'lcadir'});
	sub get_files {
        	my $FILE = $_;
       		if (-f $FILE and $FILE !~ /latest/ and $FILE !~ /svn/) {
                	if ($FILE =~ /(cdhit|uclust)/) {
                        	$options->{'mapping'} = $FILE if (/\.fasta\.txt$/ and !defined $options->{'mapping'});
                	}
                       	#$options->{'idxfasta'} = $FILE if (/\.fasta.idx$/ and !defined $options->{'idxfasta'});
                        $options->{'fasta'} = $FILE if (/(?<!trim)(?<!unique)(?<!scrap)\.fasta$/ and !defined $options->{'fasta'});
                	$options->{'biomtab'} = $FILE if ($FILE =~ /\.lca\.otu\.tab$/ and !defined $options->{'biomtab'});
                	$options->{'biomtab'} = $FILE if ($FILE =~ /otu_table\.tab$/ and !defined $options->{'biomtab'});
        	}
	}
	print "Input Options:\n";
	for my $key (sort keys $options) {
		print "\t$key : $options->{$key}\n";
	}
}
if (defined $options->{'help'}) { pod2usage(-exitval => 2, -verbose => 2); }
if (!defined $options->{'fasta'} and !defined $options->{'idxfasta'}) { pod2usage(-message => "Unspecified fasta file or indexed fasta -f -x", -verbose => 1); }
if (!defined $options->{'mapping'}) { pod2usage (-message => "Unspecified otu mapping file -m", -verbose => 1); }
if (defined $options->{'otunbr'}) {
	pod2usage(-message => "Enter the list of OTU numbers seperated by commas") if ($options->{'otunbr'} =~ /[^\d,]/);
	if (! defined $options->{'biomtab'}) { pod2usage(-message => "Unspecified classic otu table file -b"); }
} elsif (defined $options->{'taxonomy'}) {
	if (! defined $options->{'biomtab'}) { pod2usage(-message => "Unspecified classic otu table file -b"); }
} else {
	pod2usage(-message => "Please specify either otu number or taxonomy filters", -verbose => 1);
}
if (!defined $options->{'output'}) { 
	if (defined $options->{'ids-only'}) {
		$options->{'output'} = "sequences.ids";	
	} else {
		$options->{'output'} = "sequences.fasta";	
	}
}

# hash to store the otus that matches to the filter
my $IDENT = {};		# store identifications matched to taxonomy of specific OTUs
my $SEQS = {};		# store the seqids of matching OTUs based on taxonomy or OTU number

# get otu ids matching to defined filters, store taxonomy in $IDENT
if (defined $options->{'taxonomy'}) {
	my ($otufound, $otutotal) = getotus ($options->{'biomtab'}, $options->{'taxonomy'}, "taxa");
	print STDOUT "Found ". $otufound."/".$otutotal . " otus matching ". $options->{'taxonomy'}. "\n";
	die "No OTUs found\n" if ($otufound == 0);
} else {
	my ($otufound, $otutotal) = getotus ($options->{'biomtab'}, $options->{'otunbr'}, "nbr");
	print STDOUT "Found ". $otufound."/".$otutotal . " otus matching ". $options->{'otunbr'}. "\n";
	die "No OTUs found\n" if ($otufound == 0);
}

# for the otu ids in $IDENT pull out the sequence ids in $SEQS
my $seqsfound = getseqids($options->{'mapping'}, $options->{'rep-seqs'});
print STDOUT "Found ". $seqsfound . " sequences matching requirements". "\n";

if (defined $options->{'ids-only'}) {
	open OUT, ">$options->{'output'}" or die "Unable to open ouput: $0";
	foreach my $seqids (keys %{$SEQS}) {
		print OUT $seqids."\n";
	}
	close OUT;
} else {
	my $fasta;
	if (defined $options->{'idxfasta'}) { $fasta = $options->{'idxfasta'}; }
	else { $fasta = $options->{'fasta'}; }
	my $foundseqs;
	if (defined $options->{'idxfasta'} || defined $options->{'use-seqio'}) {
		$foundseqs = writeseqsSeqIO($fasta, $options->{'output'}, \$SEQS, $options->{'create-index'});
	} else {
		$foundseqs = writeseqsFile($fasta, $options->{'output'}, \$SEQS, $options->{'create-index'});
	}
	if ($foundseqs ne $seqsfound) {
		print STDOUT "Warning: only $foundseqs / $seqsfound sequences found\n";
	}
} 

#print Dumper $IDENT;

sub getseqids {
	my ($mapping, $rep) = @_;
	open MAPPING, "<$mapping" or die "Unable to open mapping file: $0";
	print STDOUT "Reading in otu mapping file ...\n";
	my $seqsfound = 0;
	while (<MAPPING>) {
		chomp;
		my $line = $_;
		my @seqs = split ("\t", $line);
		my $otuid = shift @seqs; 
		if (defined $IDENT->{$otuid}) {
			if (defined $rep) {
				$SEQS->{$seqs[0]} = $otuid;
				$seqsfound++;
			} else {
				foreach my $seq (@seqs) {
					$SEQS->{$seq} = $otuid;
					$seqsfound++;
				}
			}
		}
	}
	close MAPPING;
	print STDOUT "Done reading in mapping file!\n";
	return $seqsfound;
}

sub getotus {
	my ($otutable, $filter, $type) = @_;
	open OTUTABLE, "<".$otutable or die "Unable to open otu table $0";
	my $otuid;
	if ($type eq "nbr") {
		$filter = ",$filter,";
		$filter =~ s/\s//g;
	}
	print STDOUT "Reading in otu_table.tab ...\n";
	while (<OTUTABLE>) {
		chomp;
		next if (/^(#|$)/);
		my $taxonomy;
		($otuid, $taxonomy) = /^(\d+)\t[\d\t]*((\w+__|Un).*)/;
		if ($type eq "taxa") {
			if ($taxonomy =~ /$filter/i) {
				$IDENT->{$otuid}->{'ident'} = $taxonomy;
			}
		} elsif ($type eq "nbr") {
			if ($filter =~ /,$otuid,/) {
				$IDENT->{$otuid}->{'ident'} = $taxonomy;
			}
		} else {
			die "Invalid Type: getotus() $type\n";
		}
	}
	close OTUTABLE;
	print STDOUT "Done reading in otu_table.tab!\n";
	return (scalar keys %{$IDENT}, $otuid+1);
}

sub writeseqsFile {
	my ($fastafile, $outfile, $matchseqs) = @_;
	my $start = time;
	my $inx = undef;
	my $seqs = 0;
	open INFASTA, "<$fastafile" or die "Unable to open $fastafile\n";
	open OUTFASTA, ">$outfile" or die "Unable to open $outfile\n";
	print STDOUT "Writing sequences to file using fasta...\n";
	my $write = 0;
	while (<INFASTA>) {
		chomp;
		my $line = $_;
		if (/>(\S+)/) {
			my $seqid = $1;
			$write = 0;
			if (defined $$matchseqs->{$seqid}) {
				my $otunum = $$matchseqs->{$seqid};
				my $desc = $IDENT->{$otunum}->{'ident'};
				print OUTFASTA "\n" if ($seqs > 0); 
				print OUTFASTA ">$seqid $desc\n";
				$seqs++;
				$write = 1;
			} 
		} else {
			print OUTFASTA $line if ($write);
		}
	}
	print STDOUT "Done writing sequences to file in: ". (time - $start) ." s\n";
	return $seqs;
}

sub writeseqsSeqIO {
	my ($fastafile, $outfile, $matchseqs, $index) = @_;
	my $start = time;
	my $inx = undef;
	my $seqs = 0;
	if ($fastafile =~ /\.idx/ || defined $options->{'idxfasta'}) {
                $inx = Bio::Index::Fasta->new(-filename => $fastafile);
	} elsif (defined $index) {
		$inx = Bio::Index::Fasta->new(-filename => "tempfastafile.idx", -write_flag=> 1);
		$inx->make_index($fastafile);
	}
	my $out = Bio::SeqIO->new(-file => ">$outfile", -format => 'Fasta');
	if (! defined $inx) {
		print STDOUT "Writing sequences to file using fasta...\n";
		my $in = Bio::SeqIO->new(-file => "<$fastafile", -format => 'Fasta');
		while (my $seq = $in->next_seq()) {
			if (defined $$matchseqs->{$seq->display_id}) {
				my $otunum = $$matchseqs->{$seq->display_id};
				$seq->desc($IDENT->{$otunum}->{'ident'});
				$out->write_seq($seq);
				$seqs++;
			}
		}	
	}
	else {
		print STDOUT "Writing sequences to file using index...\n";
		foreach my $id (keys %{$$matchseqs}) {
			my $seq = $inx->fetch($id);
			if (defined $seq) {
				$seq->desc($IDENT->{$$matchseqs->{$id}}->{'ident'});
				$out->write_seq($seq);
				$seqs++;
			} else { warn "$id not found"; }
		}
	}
	print STDOUT "Done writing sequences to file in: ". (time - $start) ." s\n";
	return $seqs;
}

