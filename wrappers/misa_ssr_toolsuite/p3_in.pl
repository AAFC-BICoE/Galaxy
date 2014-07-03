#!/usr/bin/perl -w
# Author: Iyad Kandalaft
# Program name: p3_in.pl
# Description: 
# Usage: p3_in.pl misa_file.misa fasta_file.fa output.p3in


=head1 NAME

MISA to Primer3 Input Converter

=head1 SYNOPSIS

./p3_in.pl -i <misa file> -o <output primer3_in file>

=head1 DESCRIPTION

Creates a PRIMER3 input file based on SSR search results

=head1 OPTIONS

=head2 REQUIRED ARGUEMENTS

=over

=item --input-file | -i		<Multi Fasta File>

The path to the input multi-fasta file.

=item --output-file | -o		<Multi Fasta File>

The path to write the output file to.

=item --definition | -d		<String of SSR definitions>

MISA Definition for SSRs.  Should be in the format 1-10 2-6 3-5 4-5 ...

=item --interruptions | -s		<Integer of Interruption>

The maximum number of bases between two SSRs to consider them as one compound microsatellite.

=back

=cut

use warnings;
use strict;

use constant DEBUG => 0; 

use Getopt::Long;


{

my $help;
my %options = (
);


sub parse_options {
	GetOptions ( \%options,
		"input-file|i=s",
		"output-file|o=s",
		"help|h|?!" => \$help
	) or pod2usage( {
		-message => "Invalid arguements",
		-exitval => 1,
		-verbose => 1 
	} );
	
	print STDOUT "Validating options and arguements passed to the script." if ( DEBUG );
	
	( defined $help ) and
		pod2usage ( { -exitval => 0, -verbose => 2 } );

	( $options{'input-file'} ) or
		pod2usage ( { -message => "You must specify an input file path using the --input-file option",
			-exitval => 1,
			-verbose => 1  } );
			
	( $options{'output-file'} ) or
		pod2usage ( { -message => "You must specify an output file path using the --output-file option",
			-exitval => 1,
			-verbose => 1  } );
}


my $misa_file = $ARGV[0];
my $fasta_file = $ARGV[1];
my $output_file = $ARGV[2] if ( scalar( @ARGV ) > 2 );

open (IN,"<$misa_file") || die ( "\nError: Couldn't open misa.pl results file (*.misa) !\n" );
open (SRC,"<$fasta_file") || die ( "\nError: Couldn't open source file containing original FASTA sequences !\n" );
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
my $target_multiplier = 10;

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

}