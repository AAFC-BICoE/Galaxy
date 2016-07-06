 #!/usr/bin/env perl

my @name;
my @first;
my @second;
my @insert_size;
my @error;
my @orientation;

my $count;

my $output1 = shift @ARGV;
my $output2 = shift @ARGV;
my $output3 = shift @ARGV;
my $output4 = shift @ARGV;

my $s;

while ( !($ARGV[0] eq "-s"))
{

	$count = $count + 1;

	push @name , shift @ARGV;
	push @first , shift @ARGV;
	push @second, shift @ARGV;
	push @insert_size , shift @ARGV;
	push @error , shift @ARGV;
	push @orientation , shift @ARGV;
}

`mkdir tmp`;
`cd tmp`;
`touch tmp_lib`;

my $string;

$s = $count;
for(my $r = 0; $r < $count ; $r = $r + 1)
{
	$string = "$name[$r] $first[$r] $second[$r] $insert_size[$r] $error[$r] $orientation[$r]";
	`echo $string >> tmp_lib`;
	$count = $count - 1;	
}

print $s;

unshift @ARGV, "tmp_lib";
unshift @ARGV, "-l";

`SSPACE_Basic_v2.0.pl @ARGV`;

`mv standard_output.final.evidence $output1`;
`mv standard_output.final.scaffolds.fasta $output2`;
`mv standard_output.logfile.txt $output3`;
`mv standard_output.summaryfile.txt $output4`;

my $from;

print`pwd`;
print `ls`;

exit;
