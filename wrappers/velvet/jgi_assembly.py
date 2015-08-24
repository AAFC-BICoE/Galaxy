"""
Assembly classes
"""

import data
import logging
import re
import string
from cgi import escape
from galaxy.datatypes.metadata import MetadataElement
from galaxy.datatypes import metadata
import galaxy.model
from galaxy import util
from sniff import *

log = logging.getLogger(__name__)

class Assembly( data.Text ):
    """Class describing an assembly"""

    """Add metadata elements"""
    MetadataElement( name="contigs", default=0, desc="Number of contigs", readonly=True, visible=False, optional=True, no_value=0 )
    MetadataElement( name="reads", default=0, desc="Number of reads", readonly=True, visible=False, optional=True, no_value=0 )


class Ace(Assembly):
    """Class describing an assembly Ace file"""

    file_ext = "ace"

#    def init_meta( self, dataset, copy_from=None ):
#        Assembly.init_meta( self, dataset, copy_from=copy_from )

    def set_meta( self, dataset, overwrite=True, **kwd ):
        """
        Set the number of assembled contigs and read sequences and the number of data lines in dataset.
        """
        contigs = 0
        reads = 0
        for line in file( dataset.file_name ):
            line = line.strip()
            if line and line.startswith( '#' ):
                # Don't count comment lines
                continue
            if line and line.startswith( 'CO' ):
                contigs += 1
            if line and line.startswith( 'RD' ):
                reads += 1
        dataset.metadata.contigs = contigs
        dataset.metadata.reads = reads

    def set_peek( self, dataset, is_multi_byte=False ):
        if not dataset.dataset.purged:
            dataset.peek = data.get_file_peek( dataset.file_name, is_multi_byte=is_multi_byte )
            if dataset.metadata.contigs:
                dataset.blurb = "%s contigs" % util.commaify( str( dataset.metadata.contigs ) )
            else:
                dataset.blurb = data.nice_size( dataset.get_size() )
        else:
            dataset.peek = 'file does not exist'
            dataset.blurb = 'file purged from disk'

    def sniff( self, filename ):
        """
        Determines whether the file is in ace format

        An ace file contains these sections 
        AS  \d+ \d+

        CO \S+ \d+ \d+ \d+ \w
        [atcgATCGN\*]+

        BQ
        [\d\s]+

        AF \S+ [CU] \-?\d+

        BS \d+ \d+ \S+

        RD \S+ \d+ \d+ \d+
        [ATCGN\*]+

        QA \d+ \d+ \d+ \d+
        DS .*

        Currently we only check if file begins with AS

        >>> fname = get_test_fname( 'genome.ace' )
        >>> Ace().sniff( fname )
        True
        >>> fname = get_test_fname( 'genome.fasta' )
        >>> Ace().sniff( fname )
        False
        """

        try:
            fh = open( filename )
            line = fh.readline()
            line = line.strip()
            if line:
                if line.startswith( 'AS ' ):
                    fh.close()
                    return True
            fh.close()
            return False
        except:
            pass
        return False

class Velveth(Assembly):
    composite_type='basic'
    file_ext = "txt"

    def __init__(self,**kwd):
        Assembly.__init__(self,**kwd)
        self.add_composite_file('Roadmap')
        self.add_composite_file('Sequences')

