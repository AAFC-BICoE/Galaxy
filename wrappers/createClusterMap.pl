#!/usr/bin/env perl 

=head1 NAME

createClusterMap.pl

=head1 SYNOPSIS

Takes the output of a clutering program (cdhit-est, uclust) and potential 
names files from dereplication to create a file which creates a OTU or 
cluster mapping file in either mothur or qiime format. 

=head1 OPTIONS

	-i | --infile		path to input cluster file (.clstr or .uc)
	-n | --namesfile	path to names file (if deduplication was done)
	-o | --outfile		output file base name
	--qiimeotu		flag to generate qiimeotu mapping (.txt file)
	--namesotu		flag to generate namesotu mapping (.names file)
	--countotu		flag to generate counts for each cluster (.counts file)
	--rarefaction

At least one of the flags must be specified 

=head1 DESCRIPTION

Generates OTU mapping file for either QIIME or Mothur

=cut

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

my $options = {};
GetOptions($options,
		"help|h",
		"infile|i=s",
		"format=s",
		"namesfile|n=s",
		"outfile|o=s",
		"pdiff|p=s",
		"qiimeotu",
		"namesotu",
		"countotu",
		"rarefaction"
	);

pod2usage(-exitval => 2, -verbose => 2) if (defined $options->{'help'});
pod2usage("Please provide an input file") if (!defined $options->{'infile'});
pod2usage("Input file doesn't exist") if (! -e $options->{'infile'});
pod2usage("Please use one or more of --qiimeotu, --namesotu or --countotu") if (!defined $options->{'qiimeotu'} and !defined $options->{'namesotu'} and !defined $options->{'countotu'});
pod2usage("Please provide pdiff value") if (!defined $options->{'pdiff'} && $options->{'rarefaction'});
if (! defined $options->{'format'}) {
	if ($options->{'infile'} =~ /\.clstr$/) {
		$options->{'format'} = "clstr";
	} elsif ($options->{'infile'} =~ /\.uc$/) {
		$options->{'format'} = "uc";
	} else { die "Unknown file format\n"; }
} else {
	pod2usage("Please use clstr or uc") if ($options->{'format'} ne "clstr" and $options->{'format'} ne "uc");
}
# reads in names file if specified 
my $nameLookup = undef;
my $originalseqs = 0;
if (defined $options->{'namesfile'}) {
	$nameLookup = {};
	open NAMES, $options->{'namesfile'} or die "Unable to open file $options->{'namesfile'}";
	while (my $line = <NAMES>) {
		chomp $line;
		my ($key, $values) = split (/\t/, $line);
		my $count = scalar (split (/,/, $values));
		$originalseqs += $count;
		$nameLookup->{$key} = $values;
	}
}
print "Original Names: $originalseqs\n";

# reads in clstr file
open IN, $options->{'infile'};

my $clusters = {};

my $cluster;
my $totalseqs = 0;
if ($options->{'format'} eq "clstr") {
	while (my $line = <IN>) {
		if ($line =~ /^>Cluster (\d+)/) {
			$cluster = $1;
		} elsif ($line =~ /^\d+.*, >(.+?)\.\.\..*/) {
			my $seq = $1;
			# non represenative sequence
			if ($line =~ / at /) {
			    if (defined $nameLookup) {
				my @sameids = split (",", $nameLookup->{$seq});
				push @{$clusters->{$cluster}->{'members'}}, @sameids; 
				$totalseqs += scalar @sameids;
			    } else {
				push @{$clusters->{$cluster}->{'members'}}, $seq; 
				$totalseqs += 1;
			    }
			} 
			# represenative sequence
			else {
			    $clusters->{$cluster}->{'rep'} = $1;
			    if (defined $nameLookup) {
				my @sameids = split (",", $nameLookup->{$seq});
				foreach (@sameids) {
					my $tmpseq = $_;
					if ($tmpseq ne $clusters->{$cluster}->{'rep'}) {
						push @{$clusters->{$cluster}->{'members'}}, $tmpseq;
						$totalseqs += 1;
					} else {
						$totalseqs += 1;	# additional count for repseq
					} 
				}
			    }
			}		
		} else {
			die "Unexpected line: $line\nCheck input file format\n";
		}
	}
} elsif ($options->{'format'} eq "uc") {
	while (my $line = <IN>) {
		next if ($line =~ /^#/);
		#1=Type, 2=ClusterNr, 3=SeqLength or ClusterSize, 4=PctId, 5=Strand, 6=QueryStart, 7=SeedStart, 8=Alignment, 9=QueryLabel, 10=TargetLabel	
		my @field = split("\t", $line);
		my $seq = $field[8];
		my $nbr = $field[1];
		my $type = $field[0];
		if ($type =~ /^(S|C)$/) { # maybe have to add more (L=LibSeed, S=NewSeed, H=Hit, R=Reject, D=LibCluster, C=NewCluster, N=NoHit)
			if (!defined $clusters->{$nbr}->{'rep'}) {
				$clusters->{$nbr}->{'rep'} = $seq;
				if (defined $nameLookup) {
					my @sameids = split (",", $nameLookup->{$seq});
					foreach (@sameids) {
						my $tmpseq = $_;
						if ($tmpseq ne $clusters->{$nbr}->{'rep'}) {
							push @{$clusters->{$nbr}->{'members'}}, $tmpseq;
							$totalseqs += 1;
						} else {
							$totalseqs += 1;
						}
					}
			    	}
			} else {
				die "Representative Sequence do not match: $seq, $clusters->{$nbr}->{'rep'}\n" if ($seq ne $clusters->{$nbr}->{'rep'});
			}
		} elsif ($type =~ /^H$/) {
			if (defined $nameLookup) {
			my @sameids = split (",", $nameLookup->{$seq});
				push @{$clusters->{$nbr}->{'members'}}, @sameids; 
				$totalseqs += scalar @sameids;
			} else {
				push @{$clusters->{$nbr}->{'members'}}, $seq; 
				$totalseqs += 1;
			}
		} else {
			die "Unexpected line: $line\nCheck input file format\n";
		}
	}
}
print "Total Seqs: $totalseqs\n";
close IN;

if ($totalseqs ne $originalseqs) {
	warn "Sequence count of original name does not match newly generated file\nPossible extra sequence in original names\n";
}
writeNames($options, $clusters) if (defined $options->{'namesotu'}); 
writeOTUtxt($options, $clusters) if (defined $options->{'qiimeotu'}); 
writeCounts($options, $clusters) if (defined $options->{'countotu'}); 
writeOTUList($options, $clusters) if (defined $options->{'rarefaction'}); 

=head2 METHODS

=over 2

=item <writeOTUtxt>

Method to generate QIIME OTU mapping file

=cut

sub writeOTUtxt {
	my ($options, $clusters) = @_;
	
	if (defined $options->{'outfile'}) {
		open OUT, ">$options->{'outfile'}.txt";
	} else {
		open OUT, ">qiimeotu.txt";
	}
	foreach my $cluster (sort {$a <=> $b} keys %{$clusters}) {
		my $clusternum = $cluster;
		print OUT $clusternum . "\t";
		print OUT $clusters->{$cluster}->{'rep'};
		if (defined $clusters->{$cluster}->{'members'}) {
			print OUT "\t";
			print OUT (join "\t", @{$clusters->{$cluster}->{'members'}});
		}
		print OUT "\n";
	}
	close OUT;
}

=item <writeCounts>

Method to generate the number of sequence in each OTU

=cut

sub writeCounts {
	my ($options, $clusters) = @_;

	if (defined $options->{'outfile'}) {
		open OUT, ">$options->{'outfile'}.counts";
	} else {
		open OUT, ">countotu.counts";
	}

	foreach my $cluster (sort {$a <=> $b} keys %{$clusters}) {
		my $count;
		if (! $clusters->{$cluster}->{'members'}) {
			$count = 1;
		} else {
			$count = (scalar @{$clusters->{$cluster}->{'members'}})+1;
		}
		print OUT $clusters->{$cluster}->{'rep'}, "\t", $count, "\n";
	}
	
	close OUT;
}

=item <writeNames>

Method to generate Mothur OTU mapping file

=back
=cut

sub writeNames {

	my ($options, $clusters) = @_;

	if (defined $options->{'outfile'}) {
		open OUT, ">$options->{'outfile'}.names";
	} else {
		open OUT, ">mothurotu.names";
	}

	foreach my $cluster (sort {$a <=> $b} keys %{$clusters}) {
		print OUT $clusters->{$cluster}->{'rep'} . "\t";
		print OUT $clusters->{$cluster}->{'rep'};
		if (defined $clusters->{$cluster}->{'members'}) {
			print OUT ",";
			print OUT (join ",", @{$clusters->{$cluster}->{'members'}});
		}
		print OUT "\n";
	}

	close OUT;
}

sub writeOTUList {
	my ($options, $clusters) = @_;

	if (defined $options->{'outfile'}) {
		open OUT, ">$options->{'outfile'}.list";
	} else {
		open OUT, ">mothurotu.list";
	}

	my $cluster_count = scalar keys %{$clusters};
	print OUT "$options->{'pdiff'}\t$cluster_count\t";

	my $count = 0;
	foreach my $cluster (sort keys %{$clusters}) {
		print OUT (join ",", @{$clusters->{$cluster}->{'members'}});
		if ($count < $cluster_count) {
			print OUT "\t";
		}
	}
	print OUT "\n";
	close OUT;
}

