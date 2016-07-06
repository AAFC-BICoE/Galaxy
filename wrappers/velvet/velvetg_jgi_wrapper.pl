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
use Getopt::Long;
use Pod::Usage;
use List::Util qw(sum);

my @kmers;
my @files;
my $size;
my $total_cov;
my $avg_readlen;
my @kmer_list;
my $kmer_input;

sub getParam # (my $lookFor , my @arr) 
{
	my $lookFor = shift @_;
	my @arr = @_;
	my $ret = -1;
	for(my $i = 0; $i < @arr ; $i ++)
	{
		if ($arr[$i] eq $lookFor)
		{
			$ret = $i + 1;
		}	
	}
	return $ret;
}

# Bug: 2481
# Input: [read lengths, num reads], kmer (val or range), 
# OR: input reads files, kmer (val or range), 
# AND: est. genome size or contigs file
# Output: exp_cov values for each input kmer.



# Now it only accepts the fastq files for input instead of read lengths and num reads.
# Update by Jacob Jablonski.


sub get_read_lengths 
{
        my @array;
        my $r;
        for (my $i = 0; $i < @_ ; $i++)
        {
		$r = `sed -n '2p' < $_[$i]`;
		$r = length ($r);
                chomp $r;
                $r = $r - 1;
                push ( @array , $r);

        }
        return @array;
}


sub get_read_count
{
        my @array;
        my $r;
        for (my $i = 0; $i < @_ ; $i++)
        {
		$r = `head -n 1 $_[$i]`;
                chomp $r;
                my $y;
                for($y = 0; $y < length($r); $y ++)
                {
                        if (substr($r,$y-1,1) eq ":"   )
                        {
                                last;
                        }
                }
                my $str = substr($r,0, $y-1);

                my $o = `grep -c ^$str $_[$i] `;

                chomp $o;

                push (@array , $o);
        }
        return @array;
}

# Currently only works with read lengths, num reads, and genome size (e.g. no file parsing).

# From a set of kmer ranges of form e.g. 41,59,2
# and kmer values of form 31,39,47,...
# create a single array of kmer values to use.
sub get_kmer_list
{
    my %uniq_kmers = ();
	my @k_i;
	push @k_i , $kmer_input;
    for my $kr (@k_i) {
        my @fields = split(/,/, $kr);
        if (scalar @fields == 3) {
            my ($min, $max, $inc) = @fields;
            if ($min % 2 == 1 and $max % 2 == 1 and $inc % 2 == 0 and $min <= $max and $min > 0) {
                for (my $i = $min; $i <= $max; $i += $inc) {
                    $uniq_kmers{$i}++;
                }
            } else {
                die "kmer range $kr is invalid - require odd min,max, even increment, and min<=max\n";
            }
        } else {
            die "kmer range $kr is invalid - must have three entries: min,max,inc\n";
        }
    }
    for my $kl (@kmer_list) {
        my @fields = split(/,/,$kl);
        foreach my $kval (@fields) {
            if ($kval =~ /^\d+$/ and $kval %2 == 1 and $kval > 0) {
                $uniq_kmers{$kval}++;
            } else {
                print "omitting non-integer kmer '$kval'\n";
            }
        }
    }
    # return numerically sorted list of unique kmer values
    my $kmer_list = [sort {$a <=> $b} keys %uniq_kmers];
    return $kmer_list;
}

sub calc_common_stats
{
    my @rls;
    my @nrs;
    @rls =  get_read_lengths ( @files);          # @{$options->{read_length}};
    @nrs =  get_read_count( @files);          # @{$options->{num_reads}};
    ($total_cov, $avg_readlen) = ('','');
    if (scalar (@rls) != scalar (@nrs)) {
        die "Error: number of values differs between read lengths and num reads\n";
    } else {
        my $num_files = scalar @rls;
        my @products = ();
        for (my $i=0; $i<$num_files; $i++) {
            push (@products, ($rls[$i] * $nrs[$i]));
        }
        my $total_bases = sum (@products);
        $avg_readlen = $total_bases / sum (@nrs);
        $total_cov = $total_bases / $size;
    }
    return ($total_cov, $avg_readlen);
}

sub calc_exp_cov
{
    $total_cov = shift;
    $avg_readlen = shift;
    my $kmer = shift;
    my $exp_cov_float = -0.5;
    if ($avg_readlen) {
        $exp_cov_float = $total_cov * ($avg_readlen - $kmer + 1) / $avg_readlen;
    }
    my $exp_cov_rounded_int = int($exp_cov_float + 0.5);
    return $exp_cov_rounded_int;
}

my @exp_cov_list = ();

sub get_all_exp_cov
{
    my $kmer_list = get_kmer_list;
    my ($total_cov, $avg_readlen) = calc_common_stats;

    for my $kmer (@$kmer_list) {
        my $exp_cov = calc_exp_cov ($total_cov, $avg_readlen, $kmer);
        push (@exp_cov_list, $exp_cov);
    }
}

# shift wrapper args
my $velveth = shift @ARGV or die;
my $velveth_path=shift @ARGV or die;
my $velvetg_path=shift @ARGV or die;
my $velvetg_outfile=shift @ARGV or die;
my $outputID = shift @ARGV or die;
my $outpath = shift @ARGV or die;
my $extension = shift @ARGV or die;
my $kmer_select = shift @ARGV or die;

if ($kmer_select eq "yes")
{
	$size = shift @ARGV or die;
	$kmer_input = shift @ARGV or die;
	#There will be no expected coverage file.
	#instead the user enters files to create the exp_coverage
	my $files_num = `tail -n 1 $velveth`;
#	for (my $r = 0 ; $r < @ARGV ; $r ++)
#	{
#		if ( !($ARGV[$r] eq "quast.py"))
#		{
#			push @files ,  $ARGV[$r];
#		}
#		else
#		{
#			last;
#		}
#	}
#	for (my $m = 0; $m < $files_num ; $m ++)
#	{
#	#	print $files_num +3;
#		print "A\n";
#	}
	
	for (my $r = 0; $r < $files_num ; $r ++)
	{
		my $n = 2 + $r;
		my $file = `tail -n $n $velveth | head -n 1`;
		push @files, $file;
	}
}
else
{
	for (my $r = 0 ; $r < @ARGV ; $r ++)
	{
		if ( !($ARGV[$r] eq "quast.py"))
		{
			push @kmers , $ARGV[$r];
			$r = $r + 1;
			push @exp_cov_list , $ARGV[$r];
		}
		else
		{
			last;
		}
	}
}

while (@ARGV > 0)
{
	if ( !($ARGV[0] eq "quast.py"))
	{
		shift @ARGV;
	}
	else
	{
		last;
	}
}

shift @ARGV;

my $gene_select = shift @ARGV;
my $min_contig  = shift @ARGV;

# setup velvetg folder

chomp $velveth_path;
open (OUT, ">$velvetg_outfile") or die("Unable to open outfile, $velvetg_outfile: $!\n");

if ($kmer_select eq "yes")
{
	my @kVals = split (',' , $kmer_input);	
	my $minK = $kVals[0];
	my $maxK = $kVals[1];
	my $step = $kVals[2];

	while ($minK < $maxK)
	{
		push @kmers , $minK;
		$minK = $minK + $step;
	}
	get_all_exp_cov();
}
#my $expectedCov = getParam ("-exp_cov" , @ARGV) ;

-d $velvetg_path or mkdir($velvetg_path) or die("Unable to create output folder, $velvetg_path: $!\n");
print `mkdir $velvetg_path/temp`;
print "Kmers Ran: @kmers\n";	
print "EXPECTED COVERAGE: @exp_cov_list\n";


push @ARGV, "-exp_cov";

for (my $i = 0; $i < @kmers; $i ++)
{
	
	print `echo \$PATH`;
	
	chomp $velveth_path;
	chomp $velvetg_path;
	chomp $kmers[$i];
	my $rty = $velveth_path . "/kmer_$kmers[$i]" ;
#	print "LS RTY: ";
#	print `ls $rty`;
#	print `ls -al $rty`;
	print OUT $rty;		
		
	if ($kmers[$i] <= 31)
	{
		$ARGV[0] = "velvetg31";
	}
	elsif ($kmers[$i] <= 63  )
	{
		$ARGV[0] = "velvetg63";
	}
	elsif ($kmers[$i] <= 127  )
	{
		$ARGV[0] = "velvetg127";
	}
	elsif ($kmers[$i] <= 145 )
	{
		$ARGV[0] = "velvetg145";
	}
	elsif ($kmers[$i] <= 195  )
	{
		$ARGV[0] = "velvetg195";
	}
	else
	{
		$ARGV[0] = "velvetg245";
	}
	
	chomp $rty;
	
#	print "a\n$rty\na\n";
#	print "b\n$velvetg_path/temp/kmer_$kmers[$i]\nb\n";
#ss	print `\nmkdir $velvetg_path/temp/kmer_$kmers[$i]`;
#	print "\nmkdir vg: $velvetg_path/temp/kmer_$kmers[$i]";
#	print "\ncp -r -L $rty/  $velvetg_path/temp/\n";
	print `cp -r -L $rty/  $velvetg_path/temp/`;
#	print `cp -L $rty/Sequences $velvetg_path/temp/kmer_$kmers[$i]`;
#		       Sequences
#	print "\nLS DIR:\n";
#	print `ls $velvetg_path/temp/kmer_$kmers[$i]`;
#	print `ls -al $velvetg_path/temp/kmer_$kmers[$i]`;
	chomp $exp_cov_list[$i];
	$ARGV[1] = "$velvetg_path" . "/temp/kmer_$kmers[$i]" ;
#	$ARGV[$expectedCov] = $exp_cov_list[$i];
	
	push @ARGV , $exp_cov_list[$i];
	
#	print "ARGV: @ARGV \n";
	open (VELVETG, "@ARGV 2>&1|") or die("Unable to run velvetg\n");
	
	while (<VELVETG>) {
		print OUT $_;
		print if /^Final graph/;
	}
	close VELVETG;
	pop @ARGV;
	print OUT`ls $ARGV[1]`;
	chomp $outpath;
	chomp $outputID;
	chomp $kmers[$i];
	chomp $extension;

	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

	
#	print `rm $velvetg_path/temp/*`;
}

# Now we have to build the Quast command
# Should also require python
#

my @quast;

push @quast , "quast.py";

if ($gene_select eq "eukaryote" )
{
	push @quast , "--eukaryote";
}elsif ( $gene_select eq "metagenomes")
{
	push @quast , "--meta";
}


push @quast , "--min-contig";
push @quast , $min_contig;

#################################################################################

# Now we need to add the files.

for (my $i = 0 ; $i < @kmers; $i ++)
{
#	my $f = $outpath."/primary_"."$outputID"."_contigsKmer$kmers[$i]"."_visible_"."$extension";
#	print `cp $f $velvetg_path/temp/kmer$kmers[$i].fa`;
	push @quast , "$velvetg_path/temp/kmer_$kmers[$i]/contigs.fa";
}

# We should add an output file.

print `mkdir $velvetg_path/temp/quast`;
push @quast , "-o";
push @quast , "$velvetg_path/temp/quast";

print OUT "QUAST: @quast";

open (QUAST, "@quast 2>&1|") or die("Unable to run velvetg\n");
while (<QUAST>) {
	print OUT $_;
	print if /^Final graph/;
}
close QUAST;

my $loc = $outpath . "/primary_" . "$outputID" . "_Quast" . "_visible_tabular";
print `cp $velvetg_path/temp/quast/report.tsv $loc`;

for (my $i = 0; $i < @kmers ; $i ++)
{		
	print "moving kmer: $i\n";	
	my $loc = $outpath . "/primary_" . "$outputID" . "_contigsKmer$kmers[$i]" . "_visible_" . "$extension";
	chomp $velvetg_path;
	print `cp $velvetg_path/temp/kmer_$kmers[$i]/contigs.fa $loc`;

	#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#

	$loc = $outpath . "/primary_" . "$outputID" . "_statsKmer$kmers[$i]" . "_visible_txt";

	chomp $velvetg_path;
	print OUT "Loc $velvetg_path/temp/stats.txt";
	print `cp $velvetg_path/temp/kmer_$kmers[$i]/stats.txt $loc`;

	$loc = $outpath . "/primary_" . "$outputID" . "_PreGraphKmer$kmers[$i]" . "_visible_txt";
	chomp $velvetg_path;

	print `cp $velvetg_path/temp/kmer_$kmers[$i]/PreGraph $loc`;
	
	if (getParam ("-amos_file", @ARGV) != -1 && $ARGV[ getParam ("-amos_file", @ARGV) ] eq "yes" )
	{
		$loc = $outpath . "/primary_" . "$outputID" . "_VelvetAsmKmer$kmers[$i]" . "_visible_txt";
		chomp $velvetg_path;
		print `cp $velvetg_path/temp/kmer_$kmers[$i]/velvet_asm.afg" $loc`;
	}		
	if (getParam ("-unused_reads", @ARGV) != -1 && $ARGV[ getParam ("-unused_reads", @ARGV) ] eq "yes" )
	{
		$loc = $outpath . "/primary_" . "$outputID" . "_UnusedReadsKmer$kmers[$i]" . "_visible_fa";
		chomp $velvetg_path;
		print OUT "Loc $velvetg_path/temp/UnusedReads.fa";
		print `cp $velvetg_path/temp/kmer_$kmers[$i]/UnusedReads.fa $loc`;
	}
}

#my $test = $velvetg_path . "/temp/quast/report_html_aux";
#my $two  = $velvetg_path . "/temp/quast/report.html";
#print `sed -i 's\@report_html_aux\@$test\@' $two `;

#$loc = $outpath . "/primary_" . "$outputID" . "_QuastHTML" . "_visible_html";
#print `cp $velvetg_path/temp/quast/report.html $loc `;

#$loc = $outpath . "/primary_" . "$outputID" . "_QuastReport" . "_visible_pdf";
#print `cp $velvetg_path/temp/quast/report.pdf $loc `;
#################################################################################
close OUT;
exit;
