#!/usr/bin/env perl

=head1 NAME

Mauve SNP-Rich Region Parser

=head1 SYNOPSIS

./mauve_snp_parser.pl -s <mauve_snp_file> -a <mauve_genome_alignment.fa>

=head1 DESCRIPTION

Parses a Mauve show-SNP and alignment files to parse out alignments of SNP rich regions.  This tool provides the option to define how many SNPs in specific region length translates to SNP-rich region.  In addition, you can opt to eliminate Mauve's interpretation of ambiguous bases as SNPs.

=head1 OPTIONS

=head2 REQUIRED ARGUEMENTS

=over

=item --mauve-snp-file | --snp-file | -s		<mauve snp file>

Provide the Mauve SNP File path.  This file is typically produced by Mauve's find-snps script that produces a tab-formatter output.

=item --mauve-alignment-file | --alignment | -a		<mauve alignment file>

Provide the mauve alignment file path. This file is typically in XMFA format by default.  Other formats are not accepted by this script.

=back

=head2 OPTIONAL ARGUEMENTS

=over

=item --output-file | --out | -o		<filename>		Default: STDOUT

Define the output file name.  If this option is not used, the output will be printed to standard out.

=item --output-format | --format | -f		<alignment format>		Default: clustalw

Define the output alignment format to use.  See PerlDoc on Bio::AlignIO for supported output formats.  Some supported formats are xmfa, clustalw, fasta, phylip.

=item --generate-primer3-sequencing | -p3sequencing

Create a primer3 input file of flanking primers for SNP rich regions (sequencing primers)

=item --primer3-file | -p3file		<primer3 file path>		Default: primer3_in

Define the path and name of the primer3 file generated

=item --snp-count | -c		<# snps>		Default: 3

Define if an alignment is kept based on the minimum number of SNPs found (snp count) in a region length.  Specify a region length of 0 to simply include all alignments with the specific snp-count.

=item --snp-region-length | -r		<# bases>		Default: 300

Define if an alignment is kept based on the SNP count within the region length. 

=item --trim-start | -lt | -ts		<# base>		Default: 25

Ignore the first X number of bases from the start of the alignment where mauve inaccurately detects many SNPs. Set to 0 to include all bases.

=item --trim-end | -rt | -te		<# base>		Default: 25

Ignore the last X number of bases from the end of the alignment where mauve inaccurately detects many SNPs. Set to 0 to include all bases.

=item --no-ambiguous-snps

Ignore SNPs detected by mauve that include 'N' bases.

=item --no-overlapping-regions | -nooverlap

If a Primer3 input file is requested using the --generate-primer3-sequencing option, this option will ensure that SNP rich regions are mutually exclusive of other SNP rich region in the same alignment.

=item --primer-count | -pcount		<# of primers>		Default: 3

Set the number of primers that Primer3 should try to find per target

=item --help | -h | -?

Display this help message

=back

=cut

use warnings;
use strict;

{

# Toggle constant to 1 for minimal debug info, 2 for verbose debug info
use constant DEBUG => 2;

use Getopt::Long;
use Pod::Usage;
use Data::Dumper;
use Bio::AlignIO;

# Default Options
my $help;
my %options = (
	'snp-count' => 3,
	'snp-region-length' => 300,
	'output-format' => 'clustalw',
	'trim-start' => 25,
	'trim-end' => 25,
	'primer3-file' => 'primer3_in',
	'primer-count' => 3,
	'no-ambiguous-snps' => '',
	'no-overlapping-regions' => ''
);


parse_options ();
print STDOUT "Parsed options: " . Dumper( \%options ) if DEBUG;

my %snps = load_snp_file ( $options{'mauve-snp-file'} );

parse_snp ( \%options, \%snps );



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
		"mauve-snp-file|snp-file|s=s",
		"mauve-alignment-file|alignment|a=s",
		"output-file|out|o=s",
		"output-format|format|f=s",
		"generate-primer3-sequencing|p3sequencing!",
		"primer3-file|p3file=s",
		"no-overlapping-regions|nooverlap!",
		"primer-count|pcount=i",
		"trim-start|lt|ts=i",
		"trim-end|rt|te=i",
		"snp-count|c=i",
		"snp-region-length|region-length|r=i",
		"no-ambiguous-snps!",
		"help|h|?!" => \$help
	) or pod2usage( {
		-message => "Invalid arguements",
		-exitval => 1,
		-verbose => 1 
	} );

	print STDOUT "Validating options and arguements passed to the script." if ( DEBUG );

	( defined $help ) and
		pod2usage ( { -exitval => 0, -verbose => 2 } );

	( exists $options{'mauve-snp-file'} ) or
		pod2usage ( { -message => "You must specify a Mauve SNP file using the --snp",
			-exitval => 1,
			-verbose => 1  } );

	( exists $options{'mauve-alignment-file'} ) or
		pod2usage ( { -message => "You must specify a Mauve aliignment file (XMFA format) using the --alignment",
			-exitval => 1,
			-verbose => 1  } );

	( -f $options{'mauve-snp-file'} ) or
		pod2usage ( { -message => "File does not exist $options{'mauve-snp-file'}",
			-exitval => 1,
			-verbose => 1 } );

	( -f $options{'mauve-alignment-file'} ) or
		pod2usage ( { -message => "File does not exist $options{'mauve-alignment-file'}",
			-exitval => 1,
			-verbose => 1 } );

}

=head2 sub load_snp_file ()

Parameters: file path to Mauve SNP file
Returns: hash
Loads a mauve SNP file and parses the SNP coordinates in the first genome and returns them in a hash.

=cut

sub load_snp_file {
	my $snp_file = shift;
	
	open ( SNP_FH, "<", $snp_file )
		or die ( "Error opening $snp_file for writing: $!" );

	print STDOUT "Parsing Mauve's SNPs file for SNP coordinates\n" if ( DEBUG );

	my %snps;
	
	while ( <SNP_FH> ){
		if ( /^([a-z]+)\t(\d+)/i ){
			$snps{ $2 } = $1;
		}
	}

	return %snps;
}

=head2 sub parse_snp ()

Parameters: hash
Returns: boolean
Parses a SNP file and produces a fasta file with SNP rich regions

=cut

sub parse_snp {
	my %options = %{ shift () };
	my %snps = %{ shift() };

	# Open STDOUT or the file path provided by options->output-file
	open ( OUT, ">" . ( $options{'output-file'} or '-' ) )
		or die ( "Error opening $options{'output-file'} for writing: $!" );

	if ( $options{'generate-primer3-sequencing'} ) {
		open ( PRIMER3_OUT, ">" . $options{'primer3-file'} )
			or die ( "Error opening $options{'primer3-file'} for writing: $!" );
	}

	# Use Bio::AlignIO to read the mauve alignment (xmfa) format and write the alignment using the options->output-format
	my $alignments_in = Bio::AlignIO->new( -file => $options{'mauve-alignment-file'}, -format => 'xmfa');
	my $alignments_out = Bio::AlignIO->new ( -fh => \*OUT, -format => $options{'output-format'} );

	# Remove ambiguous reads if options->no-ambiguous-reads
	if ( $options{'no-ambiguous-snps'} ){
		print STDOUT "Ignoring ambiguous bases\n" if ( DEBUG );

		foreach my $pos ( keys %snps ){
			if ( $snps{ $pos } =~ m/N/i ){
				print STDOUT "Eliminating a SNP from the list $snps{ $pos } @ position $pos in reference genome\n" if ( DEBUG > 2 );
				delete $snps{ $pos };
			}
		}
	}

	print STDOUT "Parsing out alignments that meet the defined requirements\n" if ( DEBUG );


	# Iterate over every alignment section in the Mauve alignment file
	ALIGNMENT: while ( my $alignment = $alignments_in->next_aln () ) {
		# Take the reference genome sequence in the alignment
		my $sequence = $alignment->get_seq_by_pos ( 1 );
		
		print STDOUT 'Alignment - ' . $sequence->start . ' to ' . $sequence->end . "\n" if ( DEBUG > 1 );
		
		my $region_start = $sequence->start + $options{'trim-start'};
		my $snp_count = 0;
		my $include_alignment;
		my @primer_target_list;

		# Iterate over every nucleotide position in the reference seq but trim the start and end
		BASE: for ( my $pos = $sequence->start + $options{'trim-start'}; $pos <= $sequence->end - $options{'trim-end'}; $pos++ ){
			# Increment the SNP Counter if a SNP exists at this position
			if ( exists $snps{ $pos } ) {
				$snp_count++ ;
				print STDOUT " SNP @ $pos - Region start @ $region_start - SNP Count is $snp_count \n" if ( DEBUG > 1 );
			}
			
			# Include an alignment if there are at least x snps within a specific region length
			if ( 
				$snp_count >= $options{'snp-count'} and 
				( $pos - $region_start - 1 ) <= $options{'snp-region-length'} and
				( $region_start + $options{'snp-region-length'} ) <= $sequence->end - $options{'trim-end'}
			) {				
				# Add the current region to the primer target list
				# $region_start is relative to the genome, column_from_residue_number returns the region's start position relative to this sequence
				print STDOUT 'SNP Rich region found at ' . ( $region_start - $sequence->start ) . ' to ' . ( $region_start - $sequence->start + 300 ) . "\n" if ( DEBUG > 1 );
				push ( @primer_target_list, ( $region_start - $sequence->start ) . ',' . $options{'snp-region-length'} );
				
				# Flag to include alignment as a SNP rich region
				$include_alignment = 1;

				if ( $options{'no-overlapping-regions'} ) {
					# Reset the SNP count
					$snp_count = 0;
					
					# Start a new region window
					$region_start += $options{'snp-region-length'} + 1;
					$pos = $region_start;
					
					print STDOUT "Starting new Region @ $region_start\n" if ( DEBUG > 1 );
				}
			}
		
			# Skip the rest of this loop If the region we're looking at is short than the defined SNP Rich Region Length
			next BASE if ( ( $pos - $region_start ) <= $options{'snp-region-length'} );

			# Decrease the SNP count if the current SNP Rich Region window has passed a SNP
			$snp_count-- if ( exists $snps{ $region_start } );

			# Move the region window 1 base forward
			$region_start++;
		}

		# Skip the rest of the code if the alignment doesn't contain SNP Rich regions
		print STDOUT "  Alignment discarded\n" if ( not $include_alignment and DEBUG > 1 );
		next ALIGNMENT if ( not $include_alignment );

		print STDOUT " Keeping alignment - SNP rich region found\n" if ( DEBUG > 1 );
		$alignments_out->write_aln( $alignment );

		# Skip the rest of the code if the user doesn't want to generate priemr3 input for regions
		next ALIGNMENT if ( not $options{'generate-primer3-sequencing'} );

		# Generate a primer3 input segment and write it to the primer3 input file
		print PRIMER3_OUT generate_primer3_input( $sequence, \@primer_target_list, $options{'primer-count'} ); 
	}
	
	close ( OUT );
	close ( PRIMER3_OUT );
}


=head2 sub generate_primer3_input()

Parameters: bioperl seq object, array list of targets , primer opt size
Returns: string - primer3 input segment
Takes a sequence, a lister

=cut

sub generate_primer3_input {
	my $sequence = shift();
	my @target_list = @{ shift() };
	my $primer_count = shift() * scalar( @target_list );

	my $targets = join( ' ', @target_list );
	
	# Remove gaps from the sequence
	my $sequence_string = $sequence->seq;
	$sequence_string =~ tr/.-//d;
	
	my $sequence_strand = $sequence->strand eq '-1' ? '-' : '+';
	
	return join ( "\n", 
		'SEQUENCE_ID=' . '1:' . $sequence->start . ':' . $sequence->end . ' ' . $sequence_strand . ' ' . $sequence->id,
		'SEQUENCE_TEMPLATE=' . $sequence_string,
		'SEQUENCE_TARGET=' . $targets,
		'PRIMER_TASK=pick_sequencing_primers',
		'PRIMER_NUM_RETURN=' . $primer_count,
		"=\n"
		);
}


}
