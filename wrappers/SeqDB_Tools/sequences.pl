#!/usr/bin/env perl

use strict;
use warnings;

use REST::Client;
use JSON;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

my $DEBUG = 0;

{
# Default Options
my %options = (
	'command' => 'read', #CRUD commands
	'sequences' => 'sequences.fasta',
	'notfound' => 'notfound.txt'
);


parse_and_validate_options ();
get_sequences();



sub parse_and_validate_options {
	GetOptions ( \%options,
		"command=s",
		"seqids=s",
		"sequences=s",
		"notfound=s",
		"help|h|?!"
	) or pod2usage( {
		-message => "Invalid usage.",
		-exitval => 1,
		-verbose => 1 
	} );

        print STDOUT "Validating options and arguements passed to the script." if ( $DEBUG );

	( exists $options{'help'} ) and
		pod2usage ( { -exitval => 0, -verbose => 2 } );

	( $options{'command'} !~ m/(create|read|update|delete)/i ) and
		pod2usage ( { -message => "Invalid command option. --command only supports CRUD.", -exitval => 1, verbose => 1 } );
	
	if ( $options{'command'} eq 'read' ){
		( not exists $options{'seqids'} ) and
			pod2usage ( { -message => "You must specify a file containing a list of sequence identifiers.", -exitval => 1, -verbose => 1  } );
	}	
}

sub init_webservice_client {
	# Define the web service parameters
	return REST::Client->new(
		host => "http://10.117.203.95:8080/seqdbweb/webservice/v1/",
		# Populate the following when API keys are supports
		#param    => { api_key => , }
	);
}

sub get_sequences {
	my $seqdb_ws = init_webservice_client();

	print STDOUT "Opening $options{'seqids'}\n";
	open ( SEQIDS, "<" . $options{'seqids'} )
		or die "Unable to read the SeqIDs.";

	print STDOUT "Opening $options{'notfound'}\n";
	open ( NOTFOUND, ">" . $options{'notfound'} )
		or die "Unable to open $options{'notfound'} for writing.";

	print STDOUT "Opening $options{'sequences'}\n";
	open ( SEQUENCES, ">" . ($options{'sequences'}) )
		or die "Unable to write sequences.";
	
	while ( my $seqid = <SEQIDS> ){
		# Skip comment lines or empty lines
#		$seqid =~ m/^#/ or next;
#		$seqid =~ m/.+/ or next;

		# Remove leading > if they exist
#		$seqid =~ s/^>//;

		print STDOUT "Searching for $seqid\n";
		my $response = $seqdb_ws->GET( "sequence/$seqid" );

		if ( not $response ) {
			print STDOUT "$seqid - not found\n";
			print NOTFOUND $seqid . "\n";
			next;
		}

		print STDOUT "Response: " . $response->responseContent() . "\n";
		my $sequence = decode_json( $response->responseContent() )->{'entities'}[0]->{'sequence'};
		print STDOUT Dumper($sequence);
		print SEQUENCES ">" . $sequence->{'name'} . "\n";
		print SEQUENCES $sequence->{'seq'} . "\n";
	}

	close SEQIDS;
	close NOTFOUND;
	close SEQUENCES
}

}
