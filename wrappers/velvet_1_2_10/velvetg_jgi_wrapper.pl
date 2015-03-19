#!/usr/bin/env perl

# Conventience wrapper for velvetg; copies outfiles to galaxy-specified destinations.
# Please email bugs/feature requests to Edward Kirton (ESKirton@LBL.gov)
#
# History:
# - 2010/03/04 : file created
# - 2001/02/05 : added new options, outfiles; renamed to velvetg_jgi to avoid collision with the other velvetg tool

use strict;
use warnings;
use File::Copy;

# JC: 2015/03/18 Return smallest bin size >= input kmer (max 245). 
sub get_velvetg_bin
{
    my $kmer = shift;
    my @bins = (31, 63, 127, 145, 195, 245);
    my $i = 0;
    while ($bins[$i] < $kmer and $i < scalar(@bins)-1) {
        $i++;
    }
    return $bins[$i];
}

# shift wrapper args
my $velveth_path=shift @ARGV or die;
my $velvetg_path=shift @ARGV or die;
my $velvetg_outfile=shift @ARGV or die;
my $contigs_outfile=shift @ARGV or die;
my $stats_outfile=shift @ARGV or die;
my $lastgraph_outfile=shift @ARGV or die;
my $unused_reads_outfile=shift @ARGV or die;
my $amos_outfile=shift @ARGV or die;

# setup velvetg folder
die("Velveth folder does not exist: $velveth_path\n") unless -d $velveth_path;
-d $velvetg_path or mkdir($velvetg_path) or die("Unable to create output folder, $velvetg_path: $!\n");
die("velveth Sequences file does not exist: $velveth_path/Sequences") unless -f "$velveth_path/Sequences";
symlink("$velveth_path/Sequences", "$velvetg_path/Sequences");
die("velveth Roadmaps file does not exist: $velveth_path/Roadmaps") unless -f "$velveth_path/Roadmaps";
symlink("$velveth_path/Roadmaps", "$velvetg_path/Roadmaps");
die("velveth Log file does not exist: $velveth_path/Log") unless -f "$velveth_path/Log";
copy("$velveth_path/Log", "$velvetg_path/Log");

# JC: 2015/03/18 Parse Log file and use to set velvetg binary to use.
open (LOGFILE, '<', "$velvetg_path/Log");
while (my $line = <LOGFILE>) {
    if ($line =~ /^\s+velveth([0-9]+)/) {
	$ARGV[0] = "velvetg" . $1;
    }
}

# run command (remaining args, starting with exe path)
open (VELVETG, "@ARGV|") or die("Unable to run velvetg\n");
open (OUT, ">$velvetg_outfile") or die("Unable to open outfile, $velvetg_outfile: $!\n");
while (<VELVETG>) {
    print OUT $_;
    print if /^Final graph/;
}
close VELVETG;
close OUT;

# process output
unlink($contigs_outfile);
move("$velvetg_path/contigs.fa", $contigs_outfile);
unlink($stats_outfile);
move("$velvetg_path/stats.txt", $stats_outfile);

unlink($lastgraph_outfile);
if ( -f "$velvetg_path/LastGraph") {
    move("$velvetg_path/LastGraph", $lastgraph_outfile);
} elsif ( -f "$velvetg_path/Graph2") {
    move("$velvetg_path/Graph2", $lastgraph_outfile);
} else {
    open(OUT, ">$lastgraph_outfile") or die($!);
    print OUT "ERROR: $velvetg_path/LastGraph not found!\n";
    close OUT;
}
unlink($unused_reads_outfile);
move("$velvetg_path/UnusedReads.fa", $unused_reads_outfile);
if ( $amos_outfile ne 'None' ) {
    unlink($amos_outfile);
    move("$velvetg_path/velvet_asm.afg", $amos_outfile);
}
exit;
