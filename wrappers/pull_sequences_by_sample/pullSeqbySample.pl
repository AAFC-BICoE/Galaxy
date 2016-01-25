#/bin/env perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

=head1 NAME

pullSamples.pl

=head1 SYNOPSIS

Extracts sequences with modified SeqIDs based on a list of samples for input into the identification workflow. 
If no samples are provided will simply add appropriate SeqID to all sequences. 

=head1 OPTIONS

	-i | --fasta		input fasta/index fasta file with all sequences
	-o | --output		output fasta file of extracted sequences
	-g | --groups		groups file mapping each sequence to a sample
	
	-l | --list		comma seperated list of samples
	-s | --samples		file containing one sample per line to extract 
	
	--plate			plate number of the SFF file for single plates
	--samplesum		454_sample_summary.tab to pull metadata

=cut

my $options = {};
GetOptions ($options, 
			"fasta|i=s",
			"output|o=s",
			"groups|g=s",
			"list|l=s",
			"samples|s=s",
			"plate|p=s",
			"samplesum=s",
			"help|h"
);

pod2usage(-verbose => 2, -exitval => 2) if (defined $options->{'help'});
pod2usage("No groups file specified") if (! defined $options->{'groups'});
pod2usage("No fasta file specified") if (! defined $options->{'fasta'});

# get desired samples from either the list or file
my $samples = getSamples($options->{'list'}, $options->{'samples'});
#print Dumper $samples;
# get desired sequences from groups file matching desired samples
my $sequences = getSequences($options->{'groups'}, \$samples);
#print Dumper $sequences;
my $metadata = {};
if (defined $options->{'samplesum'}) {
	my $sff = 3; 	# col of sff 
	my $plate = 5;	# col of plate 
	getMetadata($options->{'samplesum'}, \$metadata, $sff, $plate);
}
# write sequences to file 
writeSeqs($options->{'fasta'}, $options->{'output'}, \$sequences, \$metadata);

sub getSamples {
	my ($list, $file) = @_;
	my $midprim = {};
	my @samps;
	
	if (defined $list) {
		#print "Using list $list\n";
		@samps = split (/,/ , $list);
	} elsif (defined $file) {
		#print "Using file $file\n";
		open SAMP, "<$file" or die "Unable to open $file\n";
		while (<SAMP>) {
			chomp;
			next if (/^\s*$/);
			s/\s//g;
			push @samps, $_;
		}
		close SAMP;
	} else {
		#print "Using all samples\n";
		push @samps, "EXTRACTALL";
	}
	foreach my $sample (@samps) {
		if (! defined $midprim->{$sample}) {
			$midprim->{$sample} = 1;
		} else {
			warn "Ignoring duplicate entry $sample\n";
		}
	}
	return $midprim;
}

sub getSequences {
	my ($groups, $samples) = @_;
	my $extractall = 0;
	my $seqs = {};
	if (defined $$samples->{'EXTRACTALL'}) {
		$extractall = 1;
	}
	open GROUP, "<$groups" or die "Unable to open $groups\n";
	while (<GROUP>) {
		chomp;
		my ($seq, $samp) = split (/\t/, $_);
		if (defined $$samples->{$samp} || $extractall) {
			$seqs->{$seq} = $samp;
		}
	}
	close GROUP;
	return $seqs;
}

sub getMetadata {
	my ($samplesum, $metadata, $sffcol, $platecol) = @_;
	open SUM, "<$samplesum" or die "Unable to open $samplesum\n";
	while (<SUM>) {
		chomp;
		my @fields = split(/\t/,$_);
		my $sff = $fields[$sffcol];
		if (! defined $$metadata->{$sff}) {
			$$metadata->{$sff} = $fields[$platecol];
		}
	}
	close SUM;
}

sub writeSeqs {
	my ($fasta, $output, $seqs, $ref) = @_;
	if (defined $output) {
		open OUTPUT, ">$output" or die "Unable to open $output\n";
	} else {
		open OUTPUT, ">&STDOUT";
	}
	if (-B $fasta) {
		# for indexed fasta file	
	} else {
		open FASTA, "<$fasta" or die "Unable to open $fasta\n";
		my $seqid;
		my $newseqid;
		my $sff;
		my $seqsfound = 0;
		while (my $line = <FASTA>) {
			chomp $line;
			if ($line =~ /^>(\S+)/) {
				$seqid = $1; 
				$newseqid = undef;
				if (defined $$seqs->{$seqid}) {
					my ($sample, $plate, $mid);
					$sample = $$seqs->{$seqid};
					($mid) = $sample =~ /MID(\d+)/;
					($sff) = $seqid =~ /^(\w{9})/;
					if (! defined $sff) {
						$sff = "null";
					}
					if (defined $$ref->{$sff}) {
						$plate = $$ref->{$sff};
						$newseqid = "P".$plate."M".$mid."_".$seqid;
					} elsif (defined $options->{'plate'}) {
						$newseqid = "P".$options->{'plate'}."M".$mid."_".$seqid;
					} else {
						$newseqid = $sample."_".$seqid;
					}
					print OUTPUT "\n" if ($seqsfound > 0); 
					$seqsfound++;
					print OUTPUT ">$newseqid\n";
				} else {
					#print OUTPUT "Skipping $seqid\n";
				}
			} else {
				print OUTPUT $line if (defined $newseqid);	
			}
		}
	}
	close FASTA;
	close OUTPUT;
}
