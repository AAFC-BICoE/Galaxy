#!/usr/bin/env perl

use Fatal;
use strict;
use warnings;


###########################################################

my @ref_files;
my $outfile = shift @ARGV;
my $outfile_id = shift @ARGV;
my $outfile_extra = shift @ARGV;
my @names;

while(!($ARGV[0] eq "fastq_screen"))
{

#	print @ARGV;

	while(!($ARGV[0] eq "NoDATABASE34908235"))
	{
		push @ref_files, $ARGV[0];
		shift @ARGV;
	}
	shift @ARGV;
	#	print `mkdir bowtie-build-output`;
	#	print `touch reference_in`;
	
	my $line;
	
	$line = $line . "$ref_files[0]";
	chomp $line;
	
	for (my $i = 1; $i < @ref_files ; $i ++)
	{
		chomp $ref_files[$i];
		$line = $line . ",$ref_files[$i]";
		chomp $line;
	#	`echo $ref_files[$i] >> reference_in`;
	#	`echo , >> reference_in`;
	}
	#`echo $line >> reference_in`;

	my @command1;

	while(!($ARGV[0] eq "end_of_bowtie"))
	{
		push @command1, $ARGV[0];
		shift @ARGV;
	}
	shift @ARGV;
	
	unshift @command1, "bowtie2-build";
	
	push @names, $command1[-1];
	my $name = pop @command1;
	chomp $name;
	push @command1 , $line ;
	push @command1 , $name ;	
#	print "\ncomd1:  @command1";
	open (VELVETK, "@command1 2>&1|") or die("Unable to run bowtie build: $!\n");
	open(OUT, ">$outfile") or die($!);
	while (<VELVETK>) {
		print $_;
		print OUT $_;
	}
	chomp $name;

	`mkdir $name`;
	my $order ;
#	$order = $order . "*";
#	chomp $order;
	`mv $name.1.bt2 $name.2.bt2 $name.3.bt2 $name.4.bt2 $name.rev.1.bt2 $name.rev.2.bt2 $name`;
}


###########################################################


#print `ls`;
#print "OUT:";
#print `ls bowtie-build-output`;
print "\n";

#`mkdir name`;
#`mv *.bt2 ./name`;

`touch fastq_screen.conf`;
`echo "THREADS	1" >> fastq_screen.conf`;

my $test_db;
my $pwd = `pwd`;
chomp $pwd;

for (my $i = 0; $i < @names ; $i ++)
{
	$test_db = "DATABASE\t$names[$i]\t$pwd/$names[$i]/$names[$i] BOWTIE2";
	`echo "$test_db" >> fastq_screen.conf`;
}

#print `ls`;

#print "333\n";
#print `cat fastq_screen.conf`;
#print "333\n";

my $conf_loc;
chomp $pwd;
$conf_loc = $pwd . "/fastq_screen.conf";

shift  @ARGV;
unshift @ARGV , $conf_loc;
unshift @ARGV , "--conf";


unshift @ARGV, $pwd;
unshift @ARGV, "--outdir";


unshift @ARGV , "fastq_screen";

#my $fastq = $ARGV[-1];
#chomp $fastq;
#$fastq = $fastq . "_screen.txt";
#chomp $fastq;
#print "\nFASTQ:$fastq\n";
#print @ARGV;

print `cat fastq_screen.conf`;

my @seq;
my @seq_names;
my @seq2;
my $size = @ARGV;


my $fake_bool = 0;


for (my $t = 0; $t < @ARGV ; $t ++)
{
	
	if ($ARGV[$t] eq "--paired")
	{
		$fake_bool = 1;
	}
	
}

print "\nARGV: @ARGV \n";

if ($fake_bool == 0)
{
	for (my $j = $size -1; $j >= 0; $j = $j - 2)
	{
		if ($ARGV[$j] eq "--nohits")
		{
			last;
		}
		push @seq, $ARGV[$j];
		push @seq_names, $ARGV[$j -1];
		splice @ARGV , $j - 1 , 1;
	}
}else
{
	
	for (my $j = $size -1; $j >= 0; $j = $j - 3)
	{
		if ($ARGV[$j] eq "--paired")
		{
			last;
		}
		push @seq2, $ARGV[$j];
		push @seq, $ARGV[$j -1 ];
		push @seq_names, $ARGV[$j - 2];
		print "remove: $ARGV[$j-2]";
		splice @ARGV , $j - 2 , 1;
	}
	
}






print "\nARGV: @ARGV \n";
open (DRRR, "@ARGV 2>&1|") or die("Unable to run fastq screen: $!\n");
open(OUT, ">>$outfile") or die($!);
while (<DRRR>) {
	print $_;
	print OUT $_;
}
#print "\n";
#print "\nFASTQ:$fastq\n";





for (my $j = 0; $j < @seq ; $j++)
{
#	for (my $r = 0; $r < length ($seq[$j]) ; $r ++)
	while (1 == 1)
	{
#		print "$seq[$j] , " . index($seq[$j], "/") . "\n";
		if ( index($seq[$j] , "/" ) != -1 )
		{
			$seq[$j] = substr( $seq[$j] , index($seq[$j], "/" ) + 1);
			chomp $seq[$j];
		}else
		{
			last;
		}
	}
}


for (my $j = 0; $j < @seq2 ; $j++)
{

	while (1 == 1)
	{

		if ( index($seq2[$j] , "/" ) != -1 )
		{
			$seq2[$j] = substr( $seq2[$j] , index($seq2[$j], "/" ) + 1);
			chomp $seq2[$j];
		}else
		{
			last;
		}
	}
}

print `ls`;

chomp $seq[0];
#print `mv $seq[0]_screen.txt $outfile`;
my $loc;
if ($fake_bool == 0)
{
	for (my $t = 0 ; $t < @seq ; $t ++)
	{
		$loc = $outfile_extra . "/primary_" . $outfile_id . "_Screen-$seq_names[$t]" . "_visible_tabular";
		chomp $loc;
		`mv $seq[$t]_screen.txt  $loc`;

		$loc = $outfile_extra . "/primary_" . $outfile_id . "_Nohits-$seq_names[$t]" . "_visible_fastq";
		chomp $loc;
		`mv $seq[$t]_no_hits.fastq $loc`;

	}
}else
{
	for (my $t = 0 ; $t < @seq ; $t ++)
	{
		$loc = $outfile_extra . "/primary_" . $outfile_id . "_Screen-$seq_names[$t]" . "_visible_tabular";
		chomp $loc;
		`mv $seq[$t]_screen.txt  $loc`;
		
		$loc = $outfile_extra . "/primary_" . $outfile_id . "_Nohits-1-$seq_names[$t]" . "_visible_fastq";
		chomp $loc;
		`mv $seq[$t]_no_hits_file.1.fastq $loc`;
	}
	for (my $t = 0; $t < @seq2 ; $t ++ )
	{
		
		$loc = $outfile_extra . "/primary_" . $outfile_id . "_Nohits-2-$seq_names[$t]" . "_visible_fastq";
		chomp $loc;
		`mv $seq2[$t]_no_hits_file.2.fastq $loc`;
		
	}
}
#`echo "Done the fastq_screen and bowtie2-build jobs" > $outfile`;

#`rm *`;

#die "TEsting";
