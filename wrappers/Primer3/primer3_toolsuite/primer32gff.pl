#!/usr/bin/perl -wi

# 	Title: 		primer32GFF
# 	Description: 	A script that use the primer3 output to generate a gff3 formatted output.
#			The script processes all primers from primer3's output using the -i/--input option and outputs the GFF formatted data to STDOUT or using the -o/--option option.
#			The user can specify the source column and name prefix in the GFF file through the --source and --naming-prefix options.
#		
#	Assumptions:	The Sequence ID in the Primer3 output should match the Sequence ID in the original fasta file.  Otherwise, the GFF feature file will not be useful since the IDs don't match.
#			To overcome this, you must drop the description from the fasta files so that the misa output file has sequence IDs that matches with those of the Fasta file.
#
#	Author:		Iyad Kandalaft


use strict;

use Getopt::Long;
use Pod::Usage;
#use Cwd 'abs_path';

# Declare Vars and set defaults
my $p3_file;
my $gff_output_file;
my $naming_prefix = "";
my $max_per_target = 5;
my $source = "Primer3";
my $help;

# Get options and override defaults
GetOptions(	"input|i=s" => \$p3_file,
		"output|o=s" => \$gff_output_file,
		"max-per-target=i" => \$max_per_target,
		"naming-prefix|n=s" => \$naming_prefix,
		"source|s=s" => \$source,
		"help|h" => \$help
);

pod2usage(-verbose => 2) && exit if $help;

# Determine whether to open STDIN or a Primer3 file
if ( defined $p3_file ){
	# Check to make sure a p3in file exists
	die("The primer3 file $p3_file does not exist.  Please check the path.\n") if ( ! -e $p3_file );

	open (P3, "<", $p3_file)
		or die("Cannot open primer3 file $p3_file for reading\n");
} else {
	open (P3, "<-")
		or die( "Unable to open STDIN for input" );
}


# Create a GFF file if the output option was used.  Otherwise, write to STDOUT.
if ( defined $gff_output_file ) {
	open(GFF, ">", $gff_output_file)
		or die("Cannot open $gff_output_file for writing\n");
} else {
	open(GFF, ">-")
		or die ("Cannot open STDOUT for writing\n");
}




# Will hold %primers{'sequence id'}{'primer number'}{'LEFT or RIGHT'}{'primer attributes'}
my (%primers, %targets);

{ 
my $seq_id = "default_seq_id";

# Parse the output from Primer3 and generate a GFF format
while ( <P3> ){
	chomp;

	if ( /^=/ ) { 
		next;
	}
	
	if ( /SEQUENCE_ID=(.+)/ ){
		$seq_id = $1;
		next 
	}

	if ( /SEQUENCE_TARGET=(.+)/ ){
		my @seq_targets = split(" ", $1);
		my $target_id;
		foreach my $target ( @seq_targets ){
			my @split = split(",", $target);
			$targets{ $seq_id }{ $target_id++ } =
			{
				'start' => $split[0] ,
				'end'	=> $split[0] + $split[1]
			}; 
		}
		
		next;
	}

	if ( /PRIMER_(?<direction>LEFT|RIGHT)_(?<id>\d+)=(?<start>\d+),(?<length>\d+)/ ){
		$primers{ $seq_id }{ $+{'id'} }{ $+{'direction'} }{'START'} = $+{'start'};
		$primers{ $seq_id }{ $+{'id'} }{ $+{'direction'} }{'END'} = $+{'start'} + $+{'length'};
		next;
	}

	if ( /PRIMER_(?<direction>LEFT|RIGHT)_(?<id>\d+)_(?<attribute>[^=]+)=(?<value>.+)/ ){
		$primers{ $seq_id }{ $+{'id'} }{ $+{'direction'} }{ $+{'attribute'} } = $+{'value'};
		next;
	}
}

}

#use Data::Dumper;
#print Dumper(\%targets);
#exit;

# Convert the %primers hash into a GFF3 formatted file and print it to STDOUT or a file
# Print the GFF version we are using
print GFF '##gff-version 3', "\n";

# Keeps count of the primers we process to provide a unique ID for each primer.
my $primer_count;

# Iterate through every primer in the hash
# For each pair of primers, create a PrimerPair feature that spans the entire flanked DNA region and has attributes of both the left and right primer.
# The PrimerPair feature acts as the parent for the left and right primers.
# For the left and right primers within the primer pair, create a child feature called Primer that spans the length of the primer only and has attributes specific to only the left or right primer.
SEQUENCE: foreach my $seq_id ( keys( %primers ) ){
	PRIMER: foreach my $p_id  ( keys( $primers{ $seq_id } ) ){
		my $primer = $primers{ $seq_id }{ $p_id };
		
		TARGET: foreach my $target_id ( keys $targets{ $seq_id } ){
			my $target = $targets{ $seq_id }{ $target_id };
			
			# Check if this primer flanks the current target, otherwise, go to the next target
			next TARGET unless ( 
						$$primer{'LEFT'}{'START'} < $$target{'start'} and
						$$primer{'RIGHT'}{'END'} > $$target{'end'}
			);

			# Skip this primer if enough primers have been found for this target
			next PRIMER if ( ++$$target{'primer_count'} > $max_per_target );

			last TARGET;			
		}

		# Create a unique ID for each primer - required by GFF3
		$primer_count++;

		print GFF $seq_id, "\t", $source, "\t", "PrimerPair", "\t"; # SeqID, Source, Type
		print GFF $$primer{'LEFT'}{'START'}, "\t"; # Start
		print GFF $$primer{'RIGHT'}{'END'}, "\t"; # End
		print GFF ".", "\t", ".", "\t", ".", "\t"; # Score, Strand, Phase
		print GFF "ID=" . $naming_prefix . "Primer.$primer_count;"; # ID Attribute
		print GFF "Name=" . $naming_prefix . "Primer.$primer_count;"; # Name Attributes
		print GFF join(";", map { "LEFT_PRIMER_$_=" . $$primer{'LEFT'}{ $_ } } keys $$primer{'LEFT'} ) . ";"; # Left Primer Attributes
		print GFF join(";", map { "RIGHT_PRIMER_$_=" . $$primer{'RIGHT'}{ $_ } } keys $$primer{'RIGHT'} ) . ";\n"; # Right Primer Attributes

		foreach my $p_direction ( keys( $primer ) ){
			print GFF $seq_id, "\t", $source, "\t", "Primer", "\t"; # SeqID, Source, Type
			print GFF $$primer{ $p_direction }{'START'}, "\t"; # Start
			print GFF $$primer{ $p_direction }{'END'}, "\t"; # End
			print GFF ".", "\t", ( $p_direction eq 'LEFT' ? "+" : "-" ), "\t", ".", "\t"; # Score, Strand, Phase
			print GFF "ID=" . $naming_prefix . "Primer.$primer_count.$p_direction;"; # ID Attribute
			print GFF "Parent=" . $naming_prefix . "Primer.$primer_count;"; # ID Attribute
			print GFF "Name=" . $naming_prefix . "Primer.$primer_count.$p_direction;"; # Name Attributes
			print GFF join(";", map { "$_=" . $$primer{ $p_direction }{ $_ } } keys $$primer{ $p_direction } ) . ";\n"; # Primer Attributes
		}
	}
}

exit;


=pod

=head1 NAME

  misa2gff.pl

=head1 SYNOPSIS

  ./primer32gff.pl [OPTIONS] -i contigs.fa.p3

  Takes Primer3's output file and converts it to GFF3 format. Limits the number of primers generated per target (default 5).

=head1 DESCRIPTION

 	A script that use the primer3 output to generate a gff3 formatted output.
	The script processes all primers from primer3's output from STDIN or using the -i/--input option and outputs the GFF formatted data to STDOUT or using the -o/--output option.
	The user can specify the source column and name prefix in the GFF file through the --source and --naming-prefix options.

	For each pair of primers in the Primer3 data, the script creates a PrimerPair feature that spans the entire flanked DNA region and has attributes of both the left and right primer.
	This PrimerPair feature acts as the parent for the left and right primers.
	For the left and right primers within a primer pair, the script creates a child feature called Primer that spans the length of the primer only and has attributes specific to only the left or right primer.

=head1 Assumptions:
	The Sequence ID in the Primer3 output should match the Sequence ID in the original fasta file.  Otherwise, the GFF feature file will not be useful since the IDs don't match.
	To overcome this, you must drop the description from the fasta files so that the misa output file has sequence IDs that matches with those of the Fasta file.

=head1 OPTIONS

=over 12

=item --input-file, -i primers.p3
  Path to Primer3's output file.  This option is required.

=item --output, --out, -o features.gff
  Outputs to file.  If this option is not used, the script outputs to STDOUT

=item --max-per-target 5
  Sets the maximum number of Primer Pairs per target to include in the GFF file.  Defaults to 5. Use 0 to include all primers.

=item --naming-prefix, -m PCR_
  Prepends the Name and ID attributes in the GFF file with the specified string.

=item --source, -s Primer3
  Sets the Source field in the GFF output (column 2) to the specified string.  Defaults to Primer3.

=item --help, -h
  Prints this help message

=back

=head1 AUTHOR

Iyad Kandalaft <ik@iyadk.com>

=cut
