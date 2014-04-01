#!/usr/bin/env python
#Dan Blankenberg
#Script that calls update_blastdb.pl to download preformatted databases

import optparse
import os
import sys
import subprocess
import time

from galaxy.util.json import from_json_string, to_json_string

def main():
    #Parse Command Line
    parser = optparse.OptionParser()
    parser.add_option( '-f', '--filename', dest='filename', action='store', type='string', default=None, help='filename' )
    parser.add_option( '-t', '--tool_data_table_name', dest='tool_data_table_name', action='store', type='string', default=None, help='tool_data_table_name' )
    (options, args) = parser.parse_args()
    
    #Take the JSON input file for parsing
    params = from_json_string( open( options.filename ).read() )
    target_directory = params[ 'output_data' ][0]['extra_files_path']
    os.mkdir( target_directory )

    #Fetch parameters from input JSON file    
    blastdb_name = params['param_dict']['db_type'].get( 'blastdb_name' )
    blastdb_type = params['param_dict']['db_type'].get( 'blastdb_type' )
    data_description = params['param_dict']['advanced'].get( 'data_description', None )
    data_id = params['param_dict']['advanced'].get( 'data_id', None )
    
    #Run update_blastdb.pl
    cmd_options = [ '--decompress' ]
    args = [ 'update_blastdb.pl' ] + cmd_options + [ blastdb_name ]
    proc = subprocess.Popen( args=args, shell=False, cwd=target_directory )
    return_code = proc.wait()

    #Check if download was successful (exit code 1)
    if return_code != 1:
        print >> sys.stderr, "Error obtaining blastdb (%s)" % return_code
        sys.exit( 1 )
    
    #Set id and description if not provided in the advanced settings
    if not data_id:
        #Use download time to create uniq id
        localtime = time.localtime()
        timeString = time.strftime("%Y%m%d%H%M%S", localtime)
        data_id = "%s_%s" % ( blastdb_name, timeString )
    
    if not data_description:
        alias_date = None
        try:
            if blastdb_type is 'nucl':
                alias_file = "%s.nal" % ( blastdb_name )
            if blastdb_type is 'prot':
                alias_file = "%s.pal" % ( blastdb_name )
            for line in open( os.path.join( target_directory, alias_file ) ):
                if line.startswith( '# Alias file created ' ):
                    alias_date = line.split( '# Alias file created ', 1 )[1].strip()
                if line.startswith( 'TITLE' ):
                    data_description = line.split( None, 1 )[1].strip()
                    break
        except Exception, e:
            print >> sys.stderr, "Error Parsing Alias file for TITLE and date: %s" % ( e )
        #If we manage to parse the pal or nal file, set description
        if alias_date and data_description:
            data_description = "%s (%s)" % ( data_description, alias_date )
    
    #If we could not parse the nal or pal file for some reason
    if not data_description:
        data_description = data_id
    
    #Prepare output string to convert into JSON format
    data_table_entry = { 'value':data_id, 'name':data_description, 'path': os.path.join( blastdb_name, data_id ), 'database_alias_name': blastdb_name }
    data_manager_dict = { 'data_tables': { options.tool_data_table_name: [ data_table_entry ]  } }
    
    #save info to json file
    with open( options.filename, 'wb' ) as fh:
        fh.write( to_json_string( data_manager_dict ) )

if __name__ == "__main__":
    main()
