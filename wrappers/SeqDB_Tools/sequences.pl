#!/usr/bin/env perl

use strict;
use warnings;

use WebService::Simple;
use Getopt::Long;

{
# Default Options
my %options = (
	'command' => 'read', #CRUD commands
	'sequences' => 'sequences.fasta',
	'notfound' => 'notfound.txt'
);


parse_and_validate_options ();






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

        print STDOUT "Validating options and arguements passed to the script." if ( DEBUG );

	( exists $options{'help'} ) and
		pod2usage ( { -exitval => 0, -verbose => 2 } );

	( $options{'command'} =~ m/(create|read|update|delete)/i ) and
		pod2usage ( { -message => "Invalid command option. --command only supports CRUD.", -exitval => 1, verbose => 1 } );
	
	if ( $options{'command'} == 'read' ){
		( not exists $options{'seqids'} ) or
			pod2usage ( { -message => "You must specify a file containing a list of sequence identifiers.", -exitval => 1, -verbose => 1  } );
	}	
}

sub init_webservice_client {
	# Define the web service parameters
	return WebService::Simple->new(
		base_url => "http://seqdb.biodiversity.agr.gc.ca/webservice/v1/",
		response_parser => 'JSON'
		# Populate the following when API keys are supports
		#param    => { api_key => , }
	);
}

sub get_sequences {
	my $seqdb_ws = init_webservice_client();

	open ( SEQIDS, "<" . ($options{'seqids'} or "-") )
		or die "Unable to read the SeqIDs.";

	open ( NOTFOUND, ">" . $options{'notfound'} )
		or die "Unable to open $options{'notfound'} for writing.";

	open ( SEQUENCES, ">" . ($options{'sequences'} or "-") )
		or die "Unable to write sequences.";
	
	while ( $seqid = <SEQIDS> ){
		$response = $seqdb_ws->get( { method => "sequence/$seqid", name => "value" } );

		if ( not $response ) {
			print NOTFOUND $seqid;
			next;
		}

		$sequence = $response->parse_response;
		print SEQUENCES ">" . $sequence{'id'};
		print SEQUENCES $sequence{'sequence'};
	}

	close SEQIDS;
	close NOTFOUND;
	close SEQUENCES
}

}
