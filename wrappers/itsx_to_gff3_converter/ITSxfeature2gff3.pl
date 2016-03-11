#/bin/env perl

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

=head1 NAME

ITSxfeature2gff3.pl

=head1 SYNOPSIS

This script converts the ITSx postions file into a gff3 file format that can
be loaded into SeqDB.

=head1 OPTIONS

	-i | --positions	input ITSx postions file
	-m | --extractions	metadata of the extracted regions
	-o | --output		gff3 output file of all the features
	
	-regions		regions to extract [default: all]
				[SSU,ITS1,5.8S,ITS2,LSU]
	-itsxver		provide the version of ITSx extractor for gff

=cut

my $options = {};
GetOptions ($options, 
			"positions|i=s",
			"extractions|m=s",
			"output|o=s",
			"log=s",
			"regions=s",
			"itsxver=s",
			"help|h"
);

pod2usage(-verbose => 2, -exitval => 2) if (defined $options->{'help'});
pod2usage("No postions file specified") if (! defined $options->{'positions'});
pod2usage("No extractions file specified") if (! defined $options->{'extractions'});
pod2usage("No output file specified") if (! defined $options->{'output'});

if (! defined $options->{'regions'} || $options->{'regions'} eq 'all') {
	$options->{'regions'} = "SSU,ITS1,5.8S,ITS2,LSU";
}

if (! defined $options->{'itsxver'}) {
	$options->{'itsxver'} = 'ITSx';
}
open INPUT, "<$options->{'positions'}" or die "Unable to open $options->{'positions'}\n";
open METADATA, "<$options->{'extractions'}" or die "Unable to open $options->{'extractions'}\n";
open OUTPUT, ">$options->{'output'}" or die "Unable to open $options->{'output'}\n";
if (! defined $options->{'log'}) {
	$options->{'log'} = 'ITSx.gff3.log';
}
open LOG, ">$options->{'log'}" or die;

my @features = split (/,/, $options->{'regions'});
my $store = {};
foreach (@features) {
	$store->{$_} = 1;
}


my $abv = {
	'A' => 'Alveolata',
	'B' => 'Bryophyta',
	'C' => 'Bacillariophyta',
	'D' => 'Amoebozoa',
	'E' => 'Euglenozoa',
	'F' => 'Fungi',
	'G' => 'Chlorophyta',
	'H' => 'Rhodophyta',
	'I' => 'Phaeophyceae',
	'L' => 'Marchantiophyta',
	'M' => 'Metazoa',
	'O' => 'Oomycota',
	'P' => 'Haptophyceae',
	'Q' => 'Raphidophyceae',
	'R' => 'Rhizaria',
	'S' => 'Synurophyceae',
	'T' => 'Tracheophyta',
	'U' => 'Eustigmatophyceae',
	'X' => 'Apusozoa',
	'Y' => 'Parabasalia',
};

my $sofa = {
	'LSU' => 'large_subunit_rRNA',
	'ITS1' => 'internal_transcribed_spacer_region',
	'5.8S' => 'rRNA_5_8S',
	'ITS2' => 'internal_transcribed_spacer_region',
	'SSU' => 'small_subunit_rRNA',
};

my $metadata = {}; 
while (<METADATA>) {
	chomp;
	my @items = split(/\t/, $_);
	my $seqid = $items[0];
	$metadata->{$seqid}->{'length'} = $items[1];
	$metadata->{$seqid}->{'origin'} = $items[2];
	$metadata->{$seqid}->{'strand'} = $items[3];
	$metadata->{$seqid}->{'domains'} = $items[4];
	$metadata->{$seqid}->{'evalue'} = $items[5];
	$metadata->{$seqid}->{'score'} = $items[6];
	$metadata->{$seqid}->{'scoresum'} = $items[7];
	$metadata->{$seqid}->{'chimeric'} = $items[12];
}

print OUTPUT "##gff-version 3\n";
while (<INPUT>) {
	chomp;
	my @items = split ("\t", $_);
	my $seqid = shift @items;
	my $cache = {};
	my $discard = {};
	foreach my $feature (@items) {
		$feature =~ s/:\s+/:/;
		my ($region, $position) = split (/:/, $feature);		
		if (defined $store->{$region}) {
			if ($position =~ /\d+-\d+/) {
				$cache->{$region} = $position;
			} else {
				$discard->{$region} = $position;
			}
		}
	}
	if (! defined $metadata->{$seqid}) {
		die "$seqid was not found\n";
	}

	my $length = $metadata->{$seqid}->{'length'};
	my $origin = $abv->{$metadata->{$seqid}->{'origin'}};
	my $strand = $metadata->{$seqid}->{'strand'};
	$strand =~ tr/01/+-/;
	my $score = $metadata->{$seqid}->{'score'};
	my $evalue = $metadata->{$seqid}->{'evalue'};

	foreach my $region (@features) {
		if (defined $cache->{$region}) {
			my ($start, $end) = split (/-/, $cache->{$region});
			print OUTPUT "$seqid\t$options->{'itsxver'}\t$sofa->{$region}\t$start\t$end\t$evalue\t$strand\t.\tName=$region;origin=$origin;length=$length\n";
			print LOG "$seqid\t$options->{'itsxver'}\t$sofa->{$region}\t$start\t$end\t$evalue\t$strand\t.\tName=$region;origin=$origin;length=$length\n";
		} else {
			print LOG "$seqid\t$options->{'itsxver'}\t$sofa->{$region}\t.\t.\t$evalue\t$strand\t.\tName=$region;origin=$origin;length=$length;Note=$discard->{$region}\n";
		}
	}
}

close INPUT;
close OUTPUT;

