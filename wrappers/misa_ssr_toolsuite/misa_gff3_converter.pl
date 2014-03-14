#!/usr/bin/env perl

=pod

=head1 NAME

  MISA to GFF3 Converter

=head1 SYNOPSIS

  ./misa_gff3_converter.pl [OPTIONS] (<STDIN>|-i file.misa)

  Converts MISA's output file into GFF3 format.

=head1 DESCRIPTION

  Convert MISA's output file into GFF format.  Creates a GFF format where there is a parent "Microsatellite" item and one ore more "Repeat" children.  Simple repeats will only have one Repeat per Microsatellite.  Compound Microsatellites will have multiple repeats with the possibility of a gap between them.

  Assumptions:	MISA does not properly parse sequence IDs from the .fasta files. It generates .misa files where the sequence ID is merged with the sequence description from the .fasta file. To overcome this, you must drop the description from the fasta files so that the misa output file has sequence IDs that matches with those of the Fasta file.

=head1 OPTIONS

=over 12

=item --input-file, -i
  Takes the path of an input misa file. If this option is not used, STDIN is used instead.

=item --output, --out, -o=outfile.fasta
  Output to file.  Otherwise, it outputs to STDOUT  

=item --naming-prefix, -m
  Prepends the Name and ID attributes in the GFF file with the specified string. 

=item --source, -s
  Sets the Source field in the GFF output (column 2) to the specified string.  Defaults to MISA.

=item --help, -h
  Prints this help message

=back

=head1 AUTHOR

Iyad Kandalaft <ik@iyadk.com>

=cut


use strict;
use warnings;


{

use Getopt::Long;
use Pod::Usage;
	
# Declare Vars and set defaults
my $misa_input_file;
my $gff_output_file;
my $naming_prefix = "";
my $source = "MISA";
my $help;

# Get options and override defaults
GetOptions(	"input|i=s" => \$misa_input_file,
		"output|o=s" => \$gff_output_file,
		"naming-prefix|n=s" => \$naming_prefix,
		"source|s=s" => \$source,
		"help|h" => \$help
);

pod2usage(-verbose => 2) && exit if $help;

# Open files or STDIN/STDOUT for input and output purposes
if ( defined $misa_input_file ) {
	open(MISA, "<", $misa_input_file)
		or die("Cannot open $misa_input_file for reading\n"); 
} else {
	open(MISA, "<-")
		or die("Cannot open STDIN for reading\n");
}

if ( defined $gff_output_file ) {
	open(GFF, ">", $gff_output_file)
		or die("Cannot open $gff_output_file for writing\n");
} else {
	open(GFF, ">-")
		or die ("Cannot open STDOUT for writing\n");
}

# Print the GFF version we are using
print GFF '##gff-version 3', "\n";

# The following section reads the MISA input line by line.
# It will then split each column and use the type column to determine if it is a simple repeat (p1, p2...) or a compound repeat (c, c*)
# It outputs a GFF feature that represents each microsatellite as a Microsatellite feature with Repeat sub-features.
# A simple repeat has 1 Microsatellite feature and 1 Repeat sub-feature.  A compound repeat has 2 or more Repeats per Microsatellite.
my $i = -1;
READLINE: while (<MISA>) {
	next READLINE if (++$i == 0);	#Skip the first line because it contains headers

	chomp; # Remove trailing space from line

	my @columns = split(/\t/); # Split the input lines tabs 
	next READLINE if ( scalar(@columns) < 7 );

	my %ssr;

	# Assign each column into a human readable form
	$ssr{"seq_id"} = $columns[0];
	$ssr{"number"} = $i;
	$ssr{"type"} = $columns[2];
	$ssr{"description"} = $columns[3];
	$ssr{"size"} = $columns[4];
	$ssr{"start"} = $columns[5];
	$ssr{"end"} = $columns[6];
			
	# Create a parent feature with the type "Microsatellite"
	print GFF 	$ssr{'seq_id'}, "\t",
			$source, "\t", 
			"Microsatellite", "\t", 
			$ssr{'start'}, "\t", 
			$ssr{'end'}, "\t", 
			".", "\t", ".", "\t", ".", "\t", 
			"ID=$naming_prefix" . "Microsat.$i;",
			"Name=$naming_prefix" . "Microsat.$i;", 
			"Type=$ssr{'type'};",
			"Description=$ssr{'description'};", 
			"Size=$ssr{'size'};",
			"\n";
			
	if ( $ssr{"type"} =~ m/^p\d+$/ ) {
		# Matches simple repeats of type p1, p2, p3...
			# Create 1 Repeat sub-feature 
			print GFF 	$ssr{'seq_id'}, "\t",
					$source, "\t",
					"Repeat", "\t", 
					$ssr{'start'}, "\t",
					$ssr{'end'}, "\t",
					".", "\t",  ".", "\t", ".", "\t",
					"ID=$naming_prefix" . "Microsat.$i.1;",
					"Parent=$naming_prefix" . "Microsat.$i;",
					"Name=$naming_prefix" . "Microsat.$i.1;",
					"Type=$ssr{'type'};",
					"Description=$ssr{'description'};",
					"Size=$ssr{'size'};",
					"\n";
	} elsif ( $ssr{"type"} =~ m/^c.?$/ ) {
		# Matches compound repeats of type c or c*
			my $section = 1;
			my $offset = 0;

			# Find each sub-repeat within a compound microsattelite
			while ( $ssr{'description'} =~ m/(?<gap>[^(]*)\((?<repeat>\w+)\)(?<multiplier>\d+)(?<star>\*?)/g ){
				# Offset the repeat by the length of the gap sequence (if one exists)
				$offset += length($+{gap});
				# Subtract from ofset because c* compound microsats start before the last nucleotide of the previous repeat. (if one exists)
				$offset -= length($+{star});
				
				print GFF 	$ssr{"seq_id"}, "\t",
						$source, "\t",
						"Repeat", "\t", 
						$ssr{'start'} + $offset, "\t",
						$ssr{'start'} + $offset + (length($+{repeat}) * $+{multiplier}) - 1, "\t",
						".", "\t",  ".", "\t", ".", "\t",
						"ID=$naming_prefix" . "Microsat.$i.$section;",
						"Parent=$naming_prefix" . "Microsat.$i;",
						"Name=$naming_prefix" . "Microsat.$i.$section;",
						"Type=$ssr{'type'};",
						"Description=($+{repeat})$+{multiplier};",
						"Size=$ssr{'size'};",
						"\n";
				
				$offset += length($+{repeat}) * $+{multiplier};
				++$section;
			}
	}
}


}
