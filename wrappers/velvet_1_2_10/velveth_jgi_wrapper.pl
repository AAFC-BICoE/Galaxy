#!/usr/bin/env perl

use strict;
use warnings;

# JC: 2015/03/18 Return smallest bin size >= input kmer (max 245). 
sub get_velveth_bin
{
    my $kmer = shift;
    my @bins = (31, 63, 127, 145, 195, 245);
    my $i = 0;
    while ($bins[$i] < $kmer and $i < scalar(@bins)-1) {
        $i++;
    }
    return $bins[$i];
}

my $start=time;
my $outfile=shift @ARGV;
my $outdir=shift @ARGV;
my $kmer=$ARGV[2];
die ("USER ERROR: Hash length (kmer) must be odd!\n") unless $kmer % 2;
my $tot_reads=0;

# JC: 2015/03/18 add correct bin suffix to velveth binary
my $vhb = get_velveth_bin ($kmer);
$ARGV[0] = "velveth" . $vhb;

open (VELVETH, "@ARGV 2>&1|") or die("Unable to run velveth: $!\n");
open(OUT, ">$outfile") or die($!);
while (<VELVETH>) {
    print OUT $_;
    if (/^\[\d+\.\d+\] (\d+) sequences found/) {
        $tot_reads += $1;
    }
}
close VELVETH;
close OUT;
die("No reads found\n") unless $tot_reads;
my $sec=time-$start;
my $min=int($sec/60);
$sec -= ($min*60);
my $hr=int($min/60);
$min -= ($hr*60);
print "$tot_reads processed in";
print " $hr hr" if $hr;
print " $min min" if $min;
print " $sec sec\n";
exit
