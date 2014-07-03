#!/usr/bin/perl

=head1 NAME

MISA Galaxy Wrapper

=head1 SYNOPSIS

./misa_wrapper -i <fasta file> -o <misa output file> -d <MISA SSR definitions> -i <MISA interruptions Length>

=head1 DESCRIPTION

Generates a misa.ini file from the definition and interruptions options. Then, misa.pl is executed with the input file specified.  Moves the misa output file to the location specified.  

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


{
	
use constant DEBUG => 0; 

use Cwd 'abs_path';
use Getopt::Long;
use Pod::Usage;

# Default Options
my $help;
my %options = (
);


parse_options();
execute_misa();


=head1 PROCEDURES

The following procedures are defined in this script.

=head2 sub parse_options ()

Parameters: none
Returns: undef
Description: Parses the command line options and validates that required options have been used.  It checks file
path to ensure that they exist. On error, the procedure exits the script  the appropriate message.

=cut 

sub parse_options {
	GetOptions ( \%options,
		"input-file|i=s",
		"output-file|o=s",
		"definition|d=s",
		"interruptions|s=s",
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

	( $options{'definition'} ) or
		pod2usage ( { -message => "You must specify a microsatellite definition for MISA using the --definition option",
			-exitval => 1,
			-verbose => 1  } );

	( $options{'interruptions'} ) or
		pod2usage ( { -message => "You must specify an interruptions length using the --interruptions option.",
			-exitval => 1,
			-verbose => 1 } );

	( -r $options{'input-file'} ) or
		pod2usage ( { -message => "File does not exist $options{'input-file'}",
			-exitval => 1,
			-verbose => 1 } );

	( $options{'definition'} =~ m/^\s*(\d-\d+(\s+|$))+\s*$/ ) or
		pod2usage ( { -message => "The definition format is incorrect: $options{'definition'}.  Please see the help text for the correct format.",
			-exitval => 1,
			-verbose => 1 } );
}

=head2 sub execute_misa ()

Parameters: none
Returns: exit value (1 for failure, 0 for success)
Description: Creates the misa.ini file, executes MISA, moves the misa output file to the output-file location, deletes the .misa.

=cut 

sub execute_misa {
	if ( -f 'misa.ini' ) {
		unlink( 'misa.ini' )
			or die 'A misa.ini file exist but it cannot be deleted.';
	}

	# Create the misa.ini file with the configuration options passed
	open INIFILE, ">misa.ini"
		or die "Unable to create the misa.ini file.";
		
	print INIFILE "definition(unit_size,min_repeats): " . $options{'definition'} . "\n";
	print INIFILE "interruptions(max_difference_between_2_SSRs): " . $options{'interruptions'} . "\n";	
	
	close INIFILE;
	
	abs_path($0) =~ m'(.+[/\\])';
	my $misa_path = $1 . 'misa.pl';
		
	system( 'perl', $misa_path, $options{'input-file'} ) == 0
		or die( "MISA failed to run: $?" );
	
	if ( ! -f $options{'input-file'} . '.misa' ){
		die( "MISA did not generate an output file." );
	}
	
	rename( $options{'input-file'} . '.misa', $options{'output-file'} )
		or die( "Unable to move the file generated by MISA: $options{'input-file'}.misa to $options{'output-file'}");

	# Delete the misa.ini file as it is no longer required
	unlink( 'misa.ini' );
}

}
