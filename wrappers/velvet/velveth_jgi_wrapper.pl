#!/usr/bin/env perl

#print `which perl`;

use Fatal;
use strict;
use warnings;
#use List::Util;
use Scalar::Util;

use IO::File;
use IO::Handle;
use List::Util qw(sum);
use Data::Dumper;
my $size;
my $cov;
my $range;
my $kmer_list;
my $last;
my $offset;
my $step;


my $start=time;
my $outfile=shift @ARGV;
my $outdir=shift @ARGV;
my $id = shift @ARGV;
my $new_file_path = shift @ARGV;

my $select_opt = shift @ARGV;

if ($select_opt eq "yes")
{
$cov    = shift @ARGV;
$size   = shift @ARGV;
$offset = shift @ARGV;
$step   = shift @ARGV;
}
else
{
$kmer_list = shift @ARGV;
}
my $tot_reads=0;
print `mkdir $outdir`;
print `mkdir $outdir/kmer`;

#$ARGV[1] = $ARGV[1] ;# ."/kmer";
my $velvet_location;
my $nums = @ARGV;
#for (my $i =0; $i < $size ; $i++)
#{
# if ( $ARGV[$i] eq "velveth"  )
# {
# $velvet_location = $i;
# }
#}
my @files;
#print "ARGS:: @ARGV \n";
for (my $j = 0; $j < $nums ; $j ++)
{
#print "$j , $ARGV[0] \n";
        if ( $ARGV[0] eq "velveth" )
        {
                last;
        }else
        {
                push @files , shift @ARGV;
        }

}
$nums = @ARGV;
for (my $i =0; $i < $nums ; $i++)
{
       if ( $ARGV[$i] eq "velveth"  )
       {
               $velvet_location = $i;
       }
}

#print "FILES @files";
open(OUT, ">$outfile") or die($!);
if ($select_opt eq "yes")
{
#print "RIGHT NOW\n";
my @velvetk_command;
push @velvetk_command , "velvetk.pl";
push @velvetk_command , "-s";
push @velvetk_command , $size;
push @velvetk_command , "-b";
push @velvetk_command , "-c";
push @velvetk_command , $cov;

for (my $i = 0; $i < @files ; $i ++ )
{
push @velvetk_command , $files[$i];
}

#print "\nVK_COMMAND @velvetk_command     ::::\n";

open (VELVETK, "@velvetk_command 2>&1|") or die("Unable to run velvetk: $!\n");
# open(OUT, ">$outfile") or die($!);
while (<VELVETK>) {
print OUT $_;
# print $_;
}
#print `cat $outfile `;
$range = `tail -n 1 $outfile`;
chomp $range;
# close OUT;
######################################

my @velvetk;
push @velvetk , "velvetk.pl";
push @velvetk , "-s";
push @velvetk , $size;
push @velvetk , "-c";
push @velvetk , $cov;

for (my $i = 0; $i < @files ; $i ++ )
{

push @velvetk , $files[$i];

}



#print "\nVK_COMMAND @velvetk ::::\n";


open (VELVETK2, "@velvetk 2>&1|") or die("Unable to run velvetk: $!\n");
open(OUT, ">$outfile") or die($!);
while (<VELVETK2>) {
print OUT $_;
# print $_;
}
#print `cat $outfile `;
$last = `tail -n 1 $outfile | cut -f1`;
chomp $last;
#print OUT "The LAST: $last\n";
#print OUT "FOCAL: $range \n";
close VELVETK2;

if ($offset % 2 != 0)
{
$offset = $offset - 1;
}

if ($step % 2   != 0)
{
$step = $step - 1;
}

my $L;
my $S;


$S = $range - $offset;
if ($S <= 0)
{
$S = 1;
}

$L = $range + $offset;

if ($L >= $last + 2)
{
$L = $last + 2;
}

$range = $S . "," . $L . "," . $step;



}else
{
$range = $kmer_list;
}





#print "velvetk.pl -s -b -c $cov @files > a ";
#my $range = `velvetk.pl -s -b -c $cov @files > a`;
#$range = `cat a`;
#print "My Range $range \n";
chomp $range;

for (my $i =0; $i < $nums ; $i++)
{
       if ( $ARGV[$i] eq "range_temp"  )
       {
               $ARGV[$i] = $range;
       }
}


my $max = $ARGV[$velvet_location +2];
$max = `echo $max | cut -d , -f 2   `;

if ($max <= 31)
{
$ARGV[$velvet_location] = "velveth31";
}
elsif ($max <= 63  )
{
$ARGV[$velvet_location] = "velveth63";
}
elsif ($max <= 127  )
{
$ARGV[$velvet_location] = "velveth127";
}
elsif ($max <= 145 )
{
$ARGV[$velvet_location] = "velveth145";
}
elsif ($max <= 195  )
{
$ARGV[$velvet_location] = "velveth195";
}
else
{
$ARGV[$velvet_location] = "velveth245";
}

if (index ( $range , ",") != -1)
{
$ARGV[1] = $ARGV[1] . "/kmer";
}
else
{
$ARGV[1] = $ARGV[1] . "/kmer_" . $range ;
}
#print OUT "The args @ARGV\n";

open (VELVETH, "@ARGV 2>&1|") or die("Unable to run velveth: $!\n");
#open(OUT, ">$outfile") or die($!);
while (<VELVETH>) {
    print OUT $_;
    if (/^\[\d+\.\d+\] (\d+) sequences found/) {
        $tot_reads += $1;
    }
}
close VELVETH;


#lets add the list of files at the bottom and end with the number of files.
my $file_size = -1;
for (my $i = 0; $i < @files ; $i ++ )
{
	print OUT "$files[$i]\n";
	$file_size = $i;
}

$file_size = $file_size + 1;
print  OUT $file_size;




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
exit;
