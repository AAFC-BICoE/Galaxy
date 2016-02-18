#!/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

=head1 NAME

extractEvidence.pl

=head1 SYNOPSIS

Takes a file containing representative seqeuence identifiers and pulls out evidence of the identifications.

=head1 OPTIONS

	-i | --input	files of representative seqids
	-o | --outdir	directory for output files
 
 Source of Evidence:
    
	--lcaout	lca output file 
	--lcalog	lca log file
	--lcatab	loc tab log file
	--blastout	tabular blast output
	--rawblast	raw blast output with alignments

=cut

my $options ={}; # hash for the options

GetOptions ($options,
	"help|h",
        "input|i=s",
        "outdir|o=s",
        "lcaout=s",
        "lcalog=s",
        "lcatab=s",
        "blastout=s",
	"rawblast=s",
        );

if (defined $options->{'help'}) { pod2usage (-exitval => 2, -verbose => 2); }
if (!defined $options->{'input'}) { pod2usage ("Unspecified input file"); }
if (!defined $options->{'outdir'}) { 
	$options->{'outdir'} = "./";
} elsif (! -d $options->{'outdir'}) {
	mkdir $options->{'outdir'} or die;
}

my $RepSeqs = getSeqs($options->{'input'});

if (defined $options->{'lcaout'}) {
	# Get the source gi list
	parseLCAout($options->{'lcaout'}, $options->{'outdir'}, \$RepSeqs);
}
if (defined $options->{'lcalog'}) {
	parseLCAlog($options->{'lcalog'}, $options->{'outdir'}, \$RepSeqs);
}
if (defined $options->{'lcatab'}) {
	parseLCAtab($options->{'lcatab'}, $options->{'outdir'}, \$RepSeqs);
}
if (defined $options->{'blastout'}) {
	parseBlastout($options->{'blastout'}, $options->{'outdir'}, \$RepSeqs);
}
if (defined $options->{'rawblast'}) {
	parseBlastraw($options->{'blastout'}, $options->{'outdir'}, \$RepSeqs);
}

sub getSeqs {
	my ($file) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	my $seqs = {};
	while (<FILE>) {
		chomp;
		next if (/^\s*#/);
		next if (/^\s*$/);
		if (! defined $seqs->{$_}) {
			$seqs->{$_} = 1;
		} else {
			warn "Skipping duplicate: $_\n";
		}
	}
	close FILE;
	return $seqs;
}

sub parseLCAout {
	my ($file, $outdir, $seqs) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	open OUT, ">$outdir/source.seqids" or die "Unable to open output file\n";
	while (<FILE>) {
		chomp;
		my $line = $_;
                my @inputparser = split (/\t/, $line);
                my $currentseqid = $inputparser[0];
                $currentseqid =~ s/Query:\s?//;
                next if ($line =~ /No suitable matches found/ or $line !~ /LCA/);
		if (defined $$seqs->{$currentseqid}) {
			foreach my $item (@inputparser) {
				$item =~ s/\s//g;
				my ($key, $value) = split (":", $item);
				if ($key eq "SourceGI") {
					my @source = split (",", $value);
					foreach (@source) {
						print OUT $_."\n";
					}
				}
                	}
		}
	}
	close FILE;
	close OUT;
}

sub parseLCAlog {
	my ($file, $outdir, $seqs) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	open OUT, ">$outdir/lca.log" or die "Unable to open output file\n";
	open TAXA, ">$outdir/hits.taxa" or die "Unable to open output file\n";
	my $parse = 0;
	my $curseq;
	my $idtotaxon = {};
	my $taxontoname = {};
	while (<FILE>) {
		chomp;
		my $line = $_;
		if ($line =~ /Processing matches for (\S+)$/) {
			my $curseq = $1;
			if (defined $$seqs->{$curseq}) {
				$parse = 1;
			} else {
				$parse = 0;
			}
		}
		if ($line =~ /Found node -> taxid: (\S+) .*rank: (\S+) .*name: (\S+)/) {
			if (! defined $taxontoname->{$1}) {
				$taxontoname->{$1}->{'rank'} = $2;
				$taxontoname->{$1}->{'name'} = $3;
			} 
		}
		if ($parse) {
			$line =~ s/^\d+ \(\d+\): //;
			print OUT $line."\n";
			if ($line =~ /\t(gi|customid): (\S+) -> txid: (\S+)/) {
				if (! defined $idtotaxon->{$2}) {
					$idtotaxon->{$2} = $3;
				}
			}
		}
	}
	print TAXA "BLASTHIT\tTAXON\tNAME\tRANK\n";
	for my $ids (sort keys %{$idtotaxon}) {
		my $taxid = $idtotaxon->{$ids};
		if (! defined $taxontoname->{$taxid}->{'name'}) {
			$taxontoname->{$taxid}->{'name'} = "Not_Logged";
		}
		if (! defined $taxontoname->{$taxid}->{'rank'}) {
			$taxontoname->{$taxid}->{'rank'} = "Not_Logged_Match_Skipped";
		}
		print TAXA "$ids\t$taxid\t$taxontoname->{$taxid}->{'name'}\t$taxontoname->{$taxid}->{'rank'}\n";
	}
	close FILE;
	close TAXA;
	close OUT;

}

sub parseLCAtab {
	my ($file, $outdir, $seqs) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	open OUT, ">$outdir/lca.log.tab" or die "Unable to open output file\n";
	while (<FILE>) {
		chomp;
		my $line = $_;
		my @items = split("\t", $line);
		if (defined $$seqs->{$items[0]}) {
			print OUT $line."\n";
		} 
	}
	close FILE;
	close OUT;

}

sub parseBlastout {
	my ($file, $outdir, $seqs) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	open OUT, ">$outdir/blast.tabular" or die "Unable to open output file\n";
	while (<FILE>) {
		chomp;
		my $line = $_;
		next if ($line =~ /^(Query|#)/);
                my ($currentquery) = /^(\S+)\t/;
                if (defined $$seqs->{$currentquery}) {
                        my @COLS = split ("\t", $line);
                        for (my $i = 0; $i < scalar @COLS; $i++) {
                                if ($i != 20 and $i != 21) {
                                        print OUT $COLS[$i]."\t";
                                }
                        }
                        print OUT "\n";
                        print OUT $COLS[20]."\n";
                        print OUT $COLS[21]."\n";
                }
	}
	close FILE;
	close OUT;
}

sub parseBlastraw {
	my ($file, $outdir, $seqs) = @_;
	open FILE, "<$file" or die "Unable to open file $file\n";
	open OUT, ">$outdir/blast.raw" or die "Unable to open output file\n";
	my $print = 0;
	while (<FILE>) {
		chomp;
		my $line = $_;
		if ($line =~ /^Query= (\S+)/) {
                        if (defined $$seqs->{$1}) {
                                $print = 1;
                        } else {
                                $print = 0;
                        }
                }
                if ($print == 1) {
                        print OUT $line."\n";
                }

	}
	close FILE;
	close OUT;
}


sub maxmin {
        my ($values, $order) = @_;
        if ($order ne "max" and $order ne "min") { return $values; }
        if ($values !~ /,/) { return $values; }
        my $max = -9e10;
        my $min = 9e10;
        my @list = split (",", $values);
        foreach my $value (@list) {
                $max = $value if ($value > $max);
                $min = $value if ($value < $min);
        }
        if ($order eq 'max') { return $max; }
        else { return $min; }
}


