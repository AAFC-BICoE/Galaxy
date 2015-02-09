#!/usr/bin/perl -w
# Author: Iyad Kandalaft
# Program name: p3_in.pl
# Description: 
# Usage: p3_in.pl misa_file.misa fasta_file.fa output.p3in


=head1 NAME

MISA to Primer3 Input Converter

=head1 SYNOPSIS

./p3_in.pl -misa-file <input_misa> --fasta-file <input_fasta> -o <output output_primer3 file>

=head1 DESCRIPTION

Creates a PRIMER3 input file based on SSR search results

=head1 OPTIONS

=head2 REQUIRED ARGUMENTS

=over

=item --misa-file | -m		<Misa File>

The path to the input multi-fasta file.

=item --fasta-file | -f		<Fasta File>

The path to the input multi-fasta file.

=item --output-file | -o		<Primer3 File>

The path to write the output file to.

=item --definition | -d		<String of SSR definitions>

MISA Definition for SSRs.  Should be in the format 1-10 2-6 3-5 4-5 ...

=item --interruptions | -s		<Integer of Interruption>

The maximum number of bases between two SSRs to consider them as one compound microsatellite.

=back

=head2 OPTIONAL ARGUMENTS

=over

=item --target-multiplier | -t		<Target multiplier>

=back

Number of primers this tool should attempt to design for each target
=cut

use warnings;
use strict;

use constant DEBUG => 0; 

use Getopt::Long;
use Pod::Usage;

my $help;
my %options = (
);

parse_options();

sub parse_options {
	GetOptions ( \%options,
		"misa-file|m=s",
		"fasta-file|f=s",
		"primer3-file|p=s",
		"target-multiplier|t=s",
		"help|h|?!" => \$help
	) or pod2usage( {
		-message => "Invalid arguements",
		-exitval => 1,
		-verbose => 1 
	} );
	
	print STDOUT "Validating options and arguements passed to the script." if ( DEBUG );
	
	( defined $help ) and
		pod2usage ( { -exitval => 0, -verbose => 2 } );

	( $options{'misa-file'} and  $options{'fasta-file'} ) or
		pod2usage ( { -message => "You must specify a misa and fasta file path using the --misa-file and --fasta-file option",
			-exitval => 1,
			-verbose => 1  } );
}


my $misa_file = $options{'misa-file'};
my $fasta_file = $options{'fasta-file'};
my $output_file = $options{'primer3-file'};
my $target_multiplier = $options{'target-multiplier'};

open (IN,"<$misa_file") || die ( "\nError: Couldn't open misa file " . $misa_file . " !\n" );
open (SRC,"<$fasta_file") || die ( "\nError: Couldn't open source file containing original FASTA sequences " . $fasta_file . " !\n" );
if ( defined $output_file ){
	open (OUT,">$output_file") or die( "Couldn't open $output_file for writing.\n" );
} else {
	open (OUT, ">-") or die( "Couldn't open STDOUT for writing.\n" );
}

undef $/;
my $in = <IN>;
study $in;

$/= ">";


my $offset_start = 3;
my $offset_end = 3;

my $count = 0;

while (<SRC>) {
	next unless (my ($id,$seq) = /(.*?)\n(.*)/s);
	$seq =~ s/[\d\s>]//g;#remove digits, spaces, line breaks,...

	my $seq_length = length($seq);

	my @sequence_targets;

	while ($in =~ /$id\t(\d+)\t\S+\t\S+\t(\d+)\t(\d+)/g) {
		my ($ssr_nr,$size,$start) = ($1,$2,$3);
		$count++;

		$start -= $offset_start;
		$size += $offset_start + $offset_end;
		
		if ( ( $start > 0 ) and ( $start + $size <= $seq_length ) ) {
			push( @sequence_targets, "$start,$size" );
		}
	}
	
	if ( scalar(@sequence_targets) > 0 ) {
		my $primers_return = scalar(@sequence_targets) * $target_multiplier;

		print OUT "PRIMER_NUM_RETURN=$primers_return\n"; # Asks Primer3 to return targets * multiplier primer pairs.
		print OUT "PRIMER_PRODUCT_SIZE_RANGE=80-300\n";
		print OUT "SEQUENCE_ID=$id\n"; # Keeps the same sequence ID as the one in the fasta file
		print OUT "SEQUENCE_TEMPLATE=$seq\n"; # The sequence from the fasta file
		print OUT "SEQUENCE_TARGET=" . join( " ", @sequence_targets ) . "\n"; # The targets to flank by the primers
		print OUT "PRIMER_MAX_END_STABILITY=250\n";
		print OUT "=\n"; # End of record
	}
}
