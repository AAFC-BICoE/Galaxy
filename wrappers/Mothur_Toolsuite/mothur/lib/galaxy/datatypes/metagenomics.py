"""
metagenomics datatypes
James E Johnson - University of Minnesota
for Mothur
"""

import logging, os, os.path, sys, time, tempfile, shutil, string, glob, re
import galaxy.model
from galaxy.datatypes.sniff import *
from galaxy.datatypes.metadata import MetadataElement
from galaxy.datatypes.data import Text
from galaxy.datatypes.tabular import Tabular
from galaxy.datatypes.sequence import Fasta
from galaxy import util
from galaxy.datatypes.images import Html
import pkg_resources
pkg_resources.require("simplejson")
import simplejson

log = logging.getLogger(__name__)

## Mothur Classes 

class Otu( Text ):

    file_ext = 'otu'
    MetadataElement( name="columns", default=0, desc="Number of columns", readonly=True, visible=True, no_value=0 )
    MetadataElement( name="labels", default=[], desc="Label Names", readonly=True, visible=True, no_value=[] )
    def __init__(self, **kwd):
        Text.__init__( self, **kwd )
    def set_meta( self, dataset, overwrite = True, **kwd ):
        if dataset.has_data():
            label_names = set()
            ncols = 0
            data_lines = 0
            comment_lines = 0
            try:
                fh = open( dataset.file_name )
                for line in fh:
                    fields = line.strip().split('\t')
                    if len(fields) >= 2: 
                        data_lines += 1
                        ncols = max(ncols,len(fields))
                        label_names.add(fields[0])
                    else:
                        comment_lines += 1
                # Set the discovered metadata values for the dataset
                dataset.metadata.data_lines = data_lines
                dataset.metadata.columns = ncols
                dataset.metadata.labels = []
                dataset.metadata.labels += label_names
                dataset.metadata.labels.sort()
            finally:
                fh.close()

    def sniff( self, filename ):
        """
        Determines whether the file is a otu (operational taxonomic unit) format
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    if line[0] != '@':
                        linePieces = line.split('\t')
                        if len(linePieces) < 2:
                            return False
                        try:
                            check = int(linePieces[1])
                            if check + 2 != len(linePieces):
                                return False
                        except ValueError:
                            return False
                        count += 1
                        if count == 5:
                            return True
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class OtuList( Otu ):
    file_ext = 'list'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/List_file
        The first column is a label that represents the distance that sequences were assigned to OTUs.
        The number in the second column is the number of OTUs that have been formed. 
        Subsequent columns contain the names of sequences within each OTU separated by a comma.
        distance_label	otu_count	OTU1	OTU2	OTUn
        """
        Otu.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        Otu.init_meta( self, dataset, copy_from=copy_from )
    def set_meta( self, dataset, overwrite = True, **kwd ):
        Otu.set_meta(self,dataset, overwrite = True, **kwd )
        """
        # too many columns to be stored in metadata
        if dataset != None and dataset.metadata.columns > 2:
            for i in range(2,dataset.metadata.columns):
               dataset.metadata.column_types[i] = 'str'
        """

class Sabund( Otu ):
    file_ext = 'sabund'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Sabund_file
        """
        Otu.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        Otu.init_meta( self, dataset, copy_from=copy_from )
    def sniff( self, filename ):
        """
        Determines whether the file is a otu (operational taxonomic unit) format
        label<TAB>count[<TAB>value(1..n)]
        
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    if line[0] != '@':
                        linePieces = line.split('\t')
                        if len(linePieces) < 2:
                            return False
                        try:
                            check = int(linePieces[1])
                            if check + 2 != len(linePieces):
                                return False
                            for i in range( 2, len(linePieces)):
                                ival = int(linePieces[i])
                        except ValueError:
                            return False
                        count += 1
                        if count >= 5:
                            return True
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class Rabund( Sabund ):
    file_ext = 'rabund'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Rabund_file
        """
        Sabund.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        Sabund.init_meta( self, dataset, copy_from=copy_from )

class GroupAbund( Otu ):
    file_ext = 'grpabund'
    MetadataElement( name="groups", default=[], desc="Group Names", readonly=True, visible=True, no_value=[] )
    def __init__(self, **kwd):
        Otu.__init__( self, **kwd )
        # self.column_names[0] = ['label']
        # self.column_names[1] = ['group']
        # self.column_names[2] = ['count']
    """
    def init_meta( self, dataset, copy_from=None ):
        Otu.init_meta( self, dataset, copy_from=copy_from )
    """
    def init_meta( self, dataset, copy_from=None ):
        Otu.init_meta( self, dataset, copy_from=copy_from )
    def set_meta( self, dataset, overwrite = True, skip=1, max_data_lines = 100000, **kwd ):
        # See if file starts with header line
        if dataset.has_data():
            label_names = set()
            group_names = set()
            data_lines = 0
            comment_lines = 0
            ncols = 0
            try:
                fh = open( dataset.file_name )
                line = fh.readline()
                fields = line.strip().split('\t')
                ncols = max(ncols,len(fields))
                if fields[0] == 'label' and fields[1] == 'Group':
                    skip=1
                    comment_lines += 1
                else:
                    skip=0
                    data_lines += 1
                    label_names.add(fields[0])
                    group_names.add(fields[1])
                for line in fh:
                    data_lines += 1
                    fields = line.strip().split('\t')
                    ncols = max(ncols,len(fields))
                    label_names.add(fields[0])
                    group_names.add(fields[1])
                # Set the discovered metadata values for the dataset
                dataset.metadata.data_lines = data_lines
                dataset.metadata.columns = ncols
                dataset.metadata.labels = []
                dataset.metadata.labels += label_names
                dataset.metadata.labels.sort()
                dataset.metadata.groups = []
                dataset.metadata.groups += group_names
                dataset.metadata.groups.sort()
                dataset.metadata.skip = skip
            finally:
                fh.close()

    def sniff( self, filename, vals_are_int=False):
        """
        Determines whether the file is a otu (operational taxonomic unit) Shared format
        label<TAB>group<TAB>count[<TAB>value(1..n)]
        The first line is column headings as of Mothur v 1.20
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    if line[0] != '@':
                        linePieces = line.split('\t')
                        if len(linePieces) < 3:
                            return False
                        if count > 0 or linePieces[0] != 'label':
                            try:
                                check = int(linePieces[2])
                                if check + 3 != len(linePieces):
                                    return False
                                for i in range( 3, len(linePieces)):
                                    if vals_are_int:
                                        ival = int(linePieces[i])
                                    else:
                                        fval = float(linePieces[i])
                            except ValueError:
                                return False
                        count += 1
                        if count >= 5:
                            return True
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class SharedRabund( GroupAbund ):
    file_ext = 'shared'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Shared_file
        A shared file is analogous to an rabund file. 
        The data in a shared file represent the number of times that an OTU is observed in multiple samples. 
        The structure of a shared file is analogous to an rabund file. 
        The first column contains the label for the comparison - this will be the value for the first column of each line from the original list file. 
        The second column contains the group name that designates where the data is coming from for that row. 
        The third column is the number of OTUs that were found between each of the groups and is the number of columns that follow. 
        Finally, the remaining columns indicate the number of sequences that belonged to each OTU from that group. 
        """
        GroupAbund.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        GroupAbund.init_meta( self, dataset, copy_from=copy_from )
    def sniff( self, filename ):
        """
        Determines whether the file is a otu (operational taxonomic unit) Shared format
        label<TAB>group<TAB>count[<TAB>value(1..n)]
        The first line is column headings as of Mothur v 1.20
        """
        # return GroupAbund.sniff(self,filename,True)
        isme = GroupAbund.sniff(self,filename,True)
        return isme
        

class RelAbund( GroupAbund ):
    file_ext = 'relabund'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Relabund_file
        The structure of a relabund file is analogous to an shared file. 
        The first column contains the label for the comparison - this will be the value for the first column of each line from the original list file (e.g. final.an.list). 
        The second column contains the group name that designates where the data is coming from for that row. Next is the number of OTUs that were found between each of the groups and is the number of columns that follow. 
        Finally, the remaining columns indicate the relative abundance of each OTU from that group.
        """
        GroupAbund.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        GroupAbund.init_meta( self, dataset, copy_from=copy_from )
    def sniff( self, filename ):
        """
        Determines whether the file is a otu (operational taxonomic unit) Relative Abundance format
        label<TAB>group<TAB>count[<TAB>value(1..n)]
        The first line is column headings as of Mothur v 1.20
        """
        # return GroupAbund.sniff(self,filename,False)
        isme = GroupAbund.sniff(self,filename,False)
        return isme

class SecondaryStructureMap(Tabular):
    file_ext = 'map'
    def __init__(self, **kwd):
        """Initialize secondary structure map datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['Map']

    def sniff( self, filename ):
        """
        Determines whether the file is a secondary structure map format
        A single column with an integer value which indicates the row that this row maps to.
        check you make sure is structMap[10] = 380 then structMap[380] = 10.
        """
        try:
            fh = open( filename )
            line_num = 0
            rowidxmap = {}
            while True:
                line = fh.readline()
                line_num += 1
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    try:
                        pointer = int(line)
                        if pointer > 0:
                            if pointer > line_num:
                                rowidxmap[line_num] = pointer 
                            elif pointer < line_num & rowidxmap[pointer] != line_num:
                                return False
                    except ValueError:
                        return False
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class SequenceAlignment( Fasta ):
    file_ext = 'align'
    def __init__(self, **kwd):
        Fasta.__init__( self, **kwd )
        """Initialize AlignCheck datatype"""

    def sniff( self, filename ):
        """
        Determines whether the file is in Mothur align fasta format
        Each sequence line must be the same length
        """
        
        try:
            fh = open( filename )
            len = -1
            while True:
                line = fh.readline()
                if not line:
                    break #EOF
                line = line.strip()
                if line: #first non-empty line
                    if line.startswith( '>' ):
                        #The next line.strip() must not be '', nor startwith '>'
                        line = fh.readline().strip()
                        if line == '' or line.startswith( '>' ):
                            break
                        if len < 0:
                            len = len(line)
                        elif len != len(line):
                            return False
                    else:
                        break #we found a non-empty line, but its not a fasta header
            if len > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class AlignCheck( Tabular ):
    file_ext = 'align.check'
    def __init__(self, **kwd):
        """Initialize AlignCheck datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','pound','dash','plus','equal','loop','tilde','total']
        self.column_types = ['str','int','int','int','int','int','int','int']
        self.comment_lines = 1

    def set_meta( self, dataset, overwrite = True, **kwd ):
        # Tabular.set_meta( self, dataset, overwrite = overwrite, first_line_is_header = True, skip = 1 )
        data_lines = 0
        if dataset.has_data():
            dataset_fh = open( dataset.file_name )
            while True:
                line = dataset_fh.readline()
                if not line: break
                data_lines += 1
            dataset_fh.close()
        dataset.metadata.comment_lines = 1
        dataset.metadata.data_lines = data_lines - 1 if data_lines > 0 else 0
        dataset.metadata.column_names = self.column_names
        dataset.metadata.column_types = self.column_types

class AlignReport(Tabular):
    """
QueryName	QueryLength	TemplateName	TemplateLength	SearchMethod	SearchScore	AlignmentMethod	QueryStart	QueryEnd	TemplateStart	TemplateEnd	PairwiseAlignmentLength	GapsInQuery	GapsInTemplate	LongestInsert	SimBtwnQuery&Template
AY457915	501		82283		1525		kmer		89.07		needleman	5		501		1		499		499			2		0		0		97.6
    """
    file_ext = 'align.report'
    def __init__(self, **kwd):
        """Initialize AlignCheck datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['QueryName','QueryLength','TemplateName','TemplateLength','SearchMethod','SearchScore',
                             'AlignmentMethod','QueryStart','QueryEnd','TemplateStart','TemplateEnd',
                             'PairwiseAlignmentLength','GapsInQuery','GapsInTemplate','LongestInsert','SimBtwnQuery&Template'
                             ]

class BellerophonChimera( Tabular ):
    file_ext = 'bellerophon.chimera'
    def __init__(self, **kwd):
        """Initialize AlignCheck datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['Name','Score','Left','Right']

class SecondaryStructureMatch(Tabular):
    """
	name	pound	dash	plus	equal	loop	tilde	total
	9_1_12	42	68	8	28	275	420	872
	9_1_14	36	68	6	26	266	422	851
	9_1_15	44	68	8	28	276	418	873
	9_1_16	34	72	6	30	267	430	860
	9_1_18	46	80	2	36	261	
    """
    def __init__(self, **kwd):
        """Initialize SecondaryStructureMatch datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','pound','dash','plus','equal','loop','tilde','total']

class DistanceMatrix( Text ):
    file_ext = 'dist'
    """Add metadata elements"""
    MetadataElement( name="sequence_count", default=0, desc="Number of sequences", readonly=True, visible=True, optional=True, no_value='?' )

    def init_meta( self, dataset, copy_from=None ):
        Text.init_meta( self, dataset, copy_from=copy_from )

    def set_meta( self, dataset, overwrite = True, skip = 0, **kwd ):
        Text.set_meta(self, dataset,overwrite = overwrite, skip = skip, **kwd )
        try:
            fh = open( dataset.file_name )
            line = fh.readline().strip().strip()
            dataset.metadata.sequence_count = int(line) 
        except Exception, e:
            log.warn("DistanceMatrix set_meta %s" % e)
        finally:
            fh.close()

class LowerTriangleDistanceMatrix(DistanceMatrix):
    file_ext = 'lower.dist'
    def __init__(self, **kwd):
        """Initialize secondary structure map datatype"""
        DistanceMatrix.__init__( self, **kwd )

    def init_meta( self, dataset, copy_from=None ):
        DistanceMatrix.init_meta( self, dataset, copy_from=copy_from )

    def sniff( self, filename ):
        """
        Determines whether the file is a lower-triangle distance matrix (phylip) format
        The first line has the number of sequences in the matrix.
        The remaining lines have the sequence name followed by a list of distances from all preceeding sequences
                5
                U68589
                U68590	0.3371
                U68591	0.3609	0.3782
                U68592	0.4155	0.3197	0.4148
                U68593	0.2872	0.1690	0.3361	0.2842
        """
        try:
            fh = open( filename )
            count = 0
            line = fh.readline()
            sequence_count = int(line.strip())
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    # Split into fields
                    linePieces = line.split('\t')
                    # Each line should have the same number of
                    # fields as the Python line index
                    linePieces = line.split('\t')
                    if len(linePieces) != (count + 1):
                        return False
                    # Distances should be floats
                    try:
                        for linePiece in linePieces[2:]:
                            check = float(linePiece)
                    except ValueError:
                        return False
                    # Increment line counter
                    count += 1
                    # Only check first 5 lines
                    if count == 5:
                        return True
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class SquareDistanceMatrix(DistanceMatrix):
    file_ext = 'square.dist'

    def __init__(self, **kwd):
        DistanceMatrix.__init__( self, **kwd )
    def init_meta( self, dataset, copy_from=None ):
        DistanceMatrix.init_meta( self, dataset, copy_from=copy_from )

    def sniff( self, filename ):
        """
        Determines whether the file is a square distance matrix (Column-formatted distance matrix) format
        The first line has the number of sequences in the matrix.
        The following lines have the sequence name in the first column plus a column for the distance to each sequence 
        in the row order in which they appear in the matrix.
               3
               U68589  0.0000  0.3371  0.3610
               U68590  0.3371  0.0000  0.3783
               U68590  0.3371  0.0000  0.3783
        """
        try:
            fh = open( filename )
            count = 0
            line = fh.readline()
            line = line.strip()
            sequence_count = int(line)
            col_cnt = seq_cnt + 1
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    if line[0] != '@':
                        linePieces = line.split('\t')
                        if len(linePieces) != col_cnt :
                            return False
                        try:
                            for i in range(1, col_cnt):
                                check = float(linePieces[i])
                        except ValueError:
                            return False
                        count += 1
                        if count == 5:
                            return True
            fh.close()
            if count < 5 and count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class PairwiseDistanceMatrix(DistanceMatrix,Tabular):
    file_ext = 'pair.dist'
    def __init__(self, **kwd):
        """Initialize secondary structure map datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['Sequence','Sequence','Distance']
        self.column_types = ['str','str','float']
    def set_meta( self, dataset, overwrite = True, skip = None, **kwd ):
        Tabular.set_meta(self, dataset,overwrite = overwrite, skip = skip, **kwd )

    def sniff( self, filename ):
        """
        Determines whether the file is a pairwise distance matrix (Column-formatted distance matrix) format
        The first and second columns have the sequence names and the third column is the distance between those sequences.
        """
        try:
            fh = open( filename )
            count = 0
            all_ints = True
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    if line[0] != '@':
                        linePieces = line.split('\t')
                        if len(linePieces) != 3:
                            return False
                        try:
                            check = float(linePieces[2])
                            try:
                                # See if it's also an integer
                                check_int = int(linePieces[2])
                            except ValueError:
                                # At least one value is not an
                                # integer
                                all_ints = False
                        except ValueError:
                            return False
                        count += 1
                        if count == 5:
                            if not all_ints:
                                return True
                            else:
                                return False
            fh.close()
            if count < 5 and count > 0:
                if not all_ints:
                    return True
                else:
                    return False
        except:
            pass
        finally:
            fh.close()
        return False

class AlignCheck(Tabular):
    file_ext = 'align.check'
    def __init__(self, **kwd):
        """Initialize secondary structure map datatype"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','pound','dash','plus','equal','loop','tilde','total']
        self.columns = 8

class Names(Tabular):
    file_ext = 'names'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Name_file
        Name file shows the relationship between a representative sequence(col 1)  and the sequences(comma-separated) it represents(col 2)
        """
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','representatives']
        self.columns = 2

class Summary(Tabular):
    file_ext = 'summary'
    def __init__(self, **kwd):
        """summarizes the quality of sequences in an unaligned or aligned fasta-formatted sequence file"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['seqname','start','end','nbases','ambigs','polymer']
        self.columns = 6

class Group(Tabular):
    file_ext = 'groups'
    MetadataElement( name="groups", default=[], desc="Group Names", readonly=True, visible=True, no_value=[] )
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Groups_file
        Group file assigns sequence (col 1)  to a group (col 2)
        """
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','group']
        self.columns = 2
    def set_meta( self, dataset, overwrite = True, skip = None, max_data_lines = None, **kwd ):
        Tabular.set_meta(self, dataset, overwrite, skip, max_data_lines)
        group_names = set() 
        try:
            fh = open( dataset.file_name )
            for line in fh:
                fields = line.strip().split('\t')
                try:
                    group_names.add(fields[1])
                except IndexError:
                    # Ignore missing 2nd column
                    pass
            dataset.metadata.groups = []
            dataset.metadata.groups += group_names
        finally:
            fh.close()

class Design(Group):
    file_ext = 'design'
    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Design_File
        Design file shows the relationship between a group(col 1) and a grouping (col 2), providing a way to merge groups.
        """
        Group.__init__( self, **kwd )

class AccNos(Tabular):
    file_ext = 'accnos'
    def __init__(self, **kwd):
        """A list of names"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['name']
        self.columns = 1

class Oligos( Text ):
    file_ext = 'oligos'

    def sniff( self, filename ):
        """
        # http://www.mothur.org/wiki/Oligos_File
        Determines whether the file is a otu (operational taxonomic unit) format
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                else:
                    if line[0] != '#':
                        linePieces = line.split('\t')
                        if len(linePieces) == 2 and re.match('forward|reverse',linePieces[0]):
                            count += 1
                            continue
                        elif len(linePieces) == 3 and re.match('barcode',linePieces[0]):
                            count += 1
                            continue
                        else:
                            return False
                        if count > 20:
                            return True
            if count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False
"""
class OtuMap( Tabular ):
    file_ext = 'otu_map'
		
    def __init__(self, **kwd):
      Tabular.__init__(self,**kwd)
      self.column_names = ['catdog','dog']
      self.column_types = ['int','float']

    def sniff(self, filename): #sniffer that detects whether it's an otu table. 
			#it appears that self refers to the object passed in, and filename will be the name of the file?
      try:
        fh = open( filename)
        line = fh.readline()
        line = line.strip()
        if line[0] != '#':
          return False
        count=0
        while True:
            #go thru the file.
            line = fh.readline()
            line = line.strip()
            if not line:
                break 
            else:
                if line[0] != '#':
                    try:
                        linePieces = line.split('\t')
                        i = int(linePieces[0])
                        f = float(linePieces[1])
                        continue
                    except:
                        return False
                #went through the file, can split!
        return True
      except:
        #failed to open file ? 
        pass
      finally:
        fh.close()
      #at this point we might as well return false..
      return False
"""
class Metadata ( Tabular ):
    file_ext='metadata'
    """
    group   dpw description
    F003D000    0   "F003D000 description"
    F003D002    2   "F003D002 description"
    F003D004    4   "F003D004 description"
    F003D006    6       "F003D006 description"
    F003D008    8       "F003D008 description"
    F003D142    142     "F003D142 description"
    F003D144    144     "F003D144 description"
    F003D146    146     "F003D146 description"
    F003D148    148     "F003D148 description"
    F003D150    150     "F003D150 description"
    MOCK.GQY1XT001  12  "MOCK.GQY1XT001 description"
    """
    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )
        self.column_names = ['group','dpw','description']
        self.column_types = ['string','int','string']
    
    def sniff (self,filename):
        try:
            fh = open (filename)
            line = fh.readline()
            line = line.strip()
            headers = line.split('\t')
            #check the header for the needed
            if headers[0] == "group" and headers[1] == "dpw" and headers[2] == "description":
                return True
        except:
            pass
        finally:
            fh.close()
        return False 



class OtuMap(Tabular):
    file_ext = 'otu_map'
    def __init__(self, **kwd):
        """A list of names"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['OTU','SEQIDS']
        self.column_types = ['int','float']

    def sniff( self, filename ):
        """
        Determines whether the file is a frequency tabular format for chimera analysis
        #1.14.0
        0	0.000
        1	0.000
        ...
        155	0.975
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                else:
                    if line[0] != '#':
                        try:
                            linePieces = line.split('\t')
                            i = int(linePieces[0])
                            continue
                        except:
                            return False
            return True
        except:
            pass
        finally:
            fh.close()
        return False


class Frequency(Tabular):
    file_ext = 'freq'
    def __init__(self, **kwd):
        """A list of names"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['position','frequency']
        self.column_types = ['int','float']

    def sniff( self, filename ):
        """
        Determines whether the file is a frequency tabular format for chimera analysis
        #1.14.0
        0	0.000
        1	0.000
        ...
        155	0.975
        """
        try:
            fh = open( filename )
						#checks first line for #
            line = fh.readline()
            line = line.strip()
            if line[0] != '#':
              return False
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                else:
                    if line[0] != '#':
                        try:
                            linePieces = line.split('\t')
                            i = int(linePieces[0])
                            f = float(linePieces[1])
                            count += 1
                            continue
                        except:
                            return False
                        if count > 20:
                            return True
            if count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class Quantile(Tabular):
    file_ext = 'quan'
    MetadataElement( name="filtered", default=False, no_value=False, optional=True , desc="Quantiles calculated using a mask", readonly=True)
    MetadataElement( name="masked", default=False, no_value=False, optional=True , desc="Quantiles calculated using a frequency filter", readonly=True)
    def __init__(self, **kwd):
        """Quantiles for chimera analysis"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['num','ten','twentyfive','fifty','seventyfive','ninetyfive','ninetynine']
        self.column_types = ['int','float','float','float','float','float','float']
    def sniff( self, filename ):
        """
        Determines whether the file is a quantiles tabular format for chimera analysis
        1	0	0	0	0	0	0
        2       0.309198        0.309198        0.37161 0.37161 0.37161 0.37161
        3       0.510982        0.563213        0.693529        0.858939        1.07442 1.20608
        ...
        """
        try:
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                else:
                    if line[0] != '#':
                        try:
                            linePieces = line.split('\t')
                            i = int(linePieces[0])
                            f = float(linePieces[1])
                            f = float(linePieces[2])
                            f = float(linePieces[3])
                            f = float(linePieces[4])
                            f = float(linePieces[5])
                            f = float(linePieces[6])
                            count += 1
                            continue
                        except:
                            return False
                        if count > 10:
                            return True
            if count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class FilteredQuantile(Quantile):
    file_ext = 'filtered.quan'
    def __init__(self, **kwd):
        """Quantiles for chimera analysis"""
        Quantile.__init__( self, **kwd )
        self.filtered = True

class MaskedQuantile(Quantile):
    file_ext = 'masked.quan'
    def __init__(self, **kwd):
        """Quantiles for chimera analysis"""
        Quantile.__init__( self, **kwd )
        self.masked = True
        self.filtered = False

class FilteredMaskedQuantile(Quantile):
    file_ext = 'filtered.masked.quan'
    def __init__(self, **kwd):
        """Quantiles for chimera analysis"""
        Quantile.__init__( self, **kwd )
        self.masked = True
        self.filtered = True

class LaneMask(Text):
    file_ext = 'filter'

    def sniff( self, filename ):
        """
        Determines whether the file is a lane mask filter:  1 line consisting of zeros and ones.
        """
        try:
            fh = open( filename )
            while True:
                buff = fh.read(1000)
                if not buff:
                    break #EOF
                else:
                    if not re.match('^[01]+$',line):
                        return False
            return True
        except:
            pass
        finally:
            close(fh)
        return False

class CountTable(Tabular):
    MetadataElement( name="groups", default=[], desc="Group Names", readonly=True, visible=True, no_value=[] )
    file_ext = 'count_table'

    def __init__(self, **kwd):
        """
        # http://www.mothur.org/wiki/Count_File
        A table with first column names and following columns integer counts
        # Example 1:
        Representative_Sequence total   
        U68630  1
        U68595  1
        U68600  1
        # Example 2 (with group columns):
        Representative_Sequence total   forest  pasture 
        U68630  1       1       0       
        U68595  1       1       0       
        U68600  1       1       0       
        U68591  1       1       0       
        U68647  1       0       1       
        """
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','total']

    def set_meta( self, dataset, overwrite = True, skip = 1, max_data_lines = None, **kwd ):
        try:
            data_lines = 0;
            fh = open( dataset.file_name )
            line = fh.readline()
            if line:
                line = line.strip()
                colnames = line.split() 
                if len(colnames) > 1:
                    dataset.metadata.columns = len( colnames )
                    if len(colnames) > 2:
                        dataset.metadata.groups = colnames[2:]
                    column_types = ['str']
                    for i in range(1,len(colnames)):
                        column_types.append('int')
                    dataset.metadata.column_types = column_types
                    dataset.metadata.comment_lines = 1
            while line:
                line = fh.readline()
                if not line: break
                data_lines += 1
            dataset.metadata.data_lines = data_lines
        finally:
            close(fh)

class RefTaxonomy(Tabular):
    file_ext = 'ref.taxonomy'
    """
        # http://www.mothur.org/wiki/Taxonomy_outline
        A table with 2 or 3 columns:
        - SequenceName
        - Taxonomy (semicolon-separated taxonomy in descending order)
        - integer ?
        Example: 2-column ( http://www.mothur.org/wiki/Taxonomy_outline )
          X56533.1        Eukaryota;Alveolata;Ciliophora;Intramacronucleata;Oligohymenophorea;Hymenostomatida;Tetrahymenina;Glaucomidae;Glaucoma;
          X97975.1        Eukaryota;Parabasalidea;Trichomonada;Trichomonadida;unclassified_Trichomonadida;
          AF052717.1      Eukaryota;Parabasalidea;
        Example: 3-column ( http://vamps.mbl.edu/resources/databases.php )
          v3_AA008	Bacteria;Firmicutes;Bacilli;Lactobacillales;Streptococcaceae;Streptococcus	5
          v3_AA016	Bacteria	120
          v3_AA019	Archaea;Crenarchaeota;Marine_Group_I	1
    """
    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','taxonomy']

    def sniff( self, filename ):
        """
        Determines whether the file is a Reference Taxonomy
        """
        try:
            pat = '^([^ \t\n\r\x0c\x0b;]+([(]\\d+[)])?(;[^ \t\n\r\x0c\x0b;]+([(]\\d+[)])?)*(;)?)$'
            fh = open( filename )
            count = 0
            # VAMPS  taxonomy files do not require a semicolon after the last taxonomy category
            # but assume assume the file will have some multi-level taxonomy assignments
            found_semicolons = False
            while True:
                line = fh.readline()
                if not line:
                    break #EOF
                line = line.strip()
                if line:
                    fields = line.split('\t')
                    if not (2 <= len(fields) <= 3):
                        return False
                    if not re.match(pat,fields[1]):
                        return False
                    if not found_semicolons and str(fields[1]).count(';') > 0:
                        found_semicolons = True
                    if len(fields) == 3:
                        check = int(fields[2])
                    count += 1
                    if count > 100:
                        break
            if count > 0:
                # This will be true if at least one entry
                # has semicolons in the 2nd column
                return found_semicolons
        except:
            pass
        finally:
            fh.close()
        return False

class SequenceTaxonomy(RefTaxonomy):
    file_ext = 'seq.taxonomy'
    """
        # http://www.mothur.org/wiki/Taxonomy_outline
        A table with 2 columns:
        - SequenceName
        - Taxonomy (semicolon-separated taxonomy in descending order)
        Example:
          X56533.1        Eukaryota;Alveolata;Ciliophora;Intramacronucleata;Oligohymenophorea;Hymenostomatida;Tetrahymenina;Glaucomidae;Glaucoma;
          X97975.1        Eukaryota;Parabasalidea;Trichomonada;Trichomonadida;unclassified_Trichomonadida;
          AF052717.1      Eukaryota;Parabasalidea;
    """
    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )
        self.column_names = ['name','taxonomy']

    def sniff( self, filename ):
        """
        Determines whether the file is a SequenceTaxonomy
        """
        try:
            pat = '^([^ \t\n\r\f\v;]+([(]\d+[)])?[;])+$'
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                if not line:
                    break #EOF
                line = line.strip()
                if line:
                    fields = line.split('\t')
                    if len(fields) != 2:
                        return False
                    if not re.match(pat,fields[1]):
                        return False
                    count += 1
                    if count > 10:
                        break
            if count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class RDPSequenceTaxonomy(SequenceTaxonomy):
    file_ext = 'rdp.taxonomy'
    """
        A table with 2 columns:
        - SequenceName
        - Taxonomy (semicolon-separated taxonomy in descending order, RDP requires exactly 6 levels deep)
        Example:
          AB001518.1      Bacteria;Bacteroidetes;Sphingobacteria;Sphingobacteriales;unclassified_Sphingobacteriales;
          AB001724.1      Bacteria;Cyanobacteria;Cyanobacteria;Family_II;GpIIa;
          AB001774.1      Bacteria;Chlamydiae;Chlamydiae;Chlamydiales;Chlamydiaceae;Chlamydophila;
    """
    def sniff( self, filename ):
        """
        Determines whether the file is a SequenceTaxonomy
        """
        try:
            pat = '^([^ \t\n\r\f\v;]+([(]\d+[)])?[;]){6}$'
            fh = open( filename )
            count = 0
            while True:
                line = fh.readline()
                if not line:
                    break #EOF
                line = line.strip()
                if line:
                    fields = line.split('\t')
                    if len(fields) != 2:
                        return False
                    if not re.match(pat,fields[1]):
                        return False
                    count += 1
                    if count > 10:
                        break
            if count > 0:
                return True
        except:
            pass
        finally:
            fh.close()
        return False

class ConsensusTaxonomy(Tabular):
    file_ext = 'cons.taxonomy'
    def __init__(self, **kwd):
        """A list of names"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['OTU','count','taxonomy']

class TaxonomySummary(Tabular):
    file_ext = 'tax.summary'
    def __init__(self, **kwd):
        """A Summary of taxon classification"""
        Tabular.__init__( self, **kwd )
        self.column_names = ['taxlevel','rankID','taxon','daughterlevels','total']

class Phylip(Text):
    file_ext = 'phy'

    def sniff( self, filename ):
        """
        Determines whether the file is in Phylip format (Interleaved or Sequential)
        The first line of the input file contains the number of species and the
        number of characters, in free format, separated by blanks (not by
        commas). The information for each species follows, starting with a
        ten-character species name (which can include punctuation marks and blanks),
        and continuing with the characters for that species.
        http://evolution.genetics.washington.edu/phylip/doc/main.html#inputfiles
        Interleaved Example:
            6   39
        Archaeopt CGATGCTTAC CGCCGATGCT
        HesperorniCGTTACTCGT TGTCGTTACT
        BaluchitheTAATGTTAAT TGTTAATGTT
        B. virginiTAATGTTCGT TGTTAATGTT
        BrontosaurCAAAACCCAT CATCAAAACC
        B.subtilisGGCAGCCAAT CACGGCAGCC
        
        TACCGCCGAT GCTTACCGC
        CGTTGTCGTT ACTCGTTGT
        AATTGTTAAT GTTAATTGT
        CGTTGTTAAT GTTCGTTGT
        CATCATCAAA ACCCATCAT
        AATCACGGCA GCCAATCAC
        """
        try:
            fh = open( filename )
            # counts line
            line = fh.readline().strip()
            linePieces = line.split()
            count = int(linePieces[0])
            seq_len = int(linePieces[1])
            # data lines
            """
            TODO check data lines
            while True:
                line = fh.readline()
                # name is the first 10 characters
                name = line[0:10]
                seq = line[10:].strip()
                # nucleic base or amino acid 1-char designators (spaces allowed)
                bases = ''.join(seq.split())
                # float per base (each separated by space)
            """
            return True
        except:
            pass
        finally:
            close(fh)
        return False


class Axes(Tabular):
    file_ext = 'axes'

    def __init__(self, **kwd):
        """Initialize axes datatype"""
        Tabular.__init__( self, **kwd )
    def sniff( self, filename ):
        """
        Determines whether the file is an axes format
        The first line may have column headings.
        The following lines have the name in the first column plus float columns for each axis.
		==> 98_sq_phylip_amazon.fn.unique.pca.axes <==
		group   axis1   axis2
		forest  0.000000        0.145743        
		pasture 0.145743        0.000000        
		
		==> 98_sq_phylip_amazon.nmds.axes <==
        		axis1   axis2   
		U68589  0.262608        -0.077498       
		U68590  0.027118        0.195197        
		U68591  0.329854        0.014395        
        """
        try:
            fh = open( filename )
            count = 0
            line = fh.readline()
            line = line.strip()
            col_cnt = None
            all_integers = True
            while True:
                line = fh.readline()
                line = line.strip()
                if not line:
                    break #EOF
                if line:
                    fields = line.split('\t')
                    if col_cnt == None:  # ignore values in first line as they may be column headings
                        col_cnt = len(fields)
                        # There should be at least 2 columns
                        if col_cnt < 2:
                            return False
                    else:  
                        if len(fields) != col_cnt :
                            return False
                        try:
                            for i in range(1, col_cnt):
                                check = float(fields[i])
                                # Check abs value is <= 1.0
                                if abs(check) > 1.0:
                                    return False
                                # Also test for whether value is an integer
                                try:
                                    check = int(fields[i])
                                except ValueError:
                                    all_integers = False
                        except ValueError:
                            return False
                        count += 1
                    if count > 10:
                        break
            if count > 0:
                if not all_integers:
                    # At least one value was a float
                    return True
                else:
                    return False
        except:
            pass
        finally:
            fh.close()
        return False

class SffFlow(Tabular):
    MetadataElement( name="flow_values", default="", no_value="", optional=True , desc="Total number of flow values", readonly=True)
    MetadataElement( name="flow_order", default="TACG", no_value="TACG", desc="Total number of flow values", readonly=False)
    file_ext = 'sff.flow'
    """
        # http://www.mothur.org/wiki/Flow_file
        The first line is the total number of flow values - 800 for Titanium data. For GS FLX it would be 400. 
        Following lines contain:
        - SequenceName
        - the number of useable flows as defined by 454's software
        - the flow intensity for each base going in the order of TACG.
        Example:
          800
          GQY1XT001CQL4K 85 1.04 0.00 1.00 0.02 0.03 1.02 0.05 ...
          GQY1XT001CQIRF 84 1.02 0.06 0.98 0.06 0.09 1.05 0.07 ... 
          GQY1XT001CF5YW 88 1.02 0.02 1.01 0.04 0.06 1.02 0.03 ...
    """
    def __init__(self, **kwd):
        Tabular.__init__( self, **kwd )

    def set_meta( self, dataset, overwrite = True, skip = 1, max_data_lines = None, **kwd ):
        Tabular.set_meta(self, dataset, overwrite, 1, max_data_lines)
        try:
            fh = open( dataset.file_name )
            line = fh.readline()
            line = line.strip()
            flow_values = int(line)
            dataset.metadata.flow_values = flow_values
        finally:
            fh.close()

    def make_html_table( self, dataset, skipchars=[] ):
        """Create HTML table, used for displaying peek"""
        out = ['<table cellspacing="0" cellpadding="3">']
        comments = []
        try:
            # Generate column header
            out.append('<tr>')
            out.append( '<th>%d. Name</th>' % 1 )
            out.append( '<th>%d. Flows</th>' % 2 )
            for i in range( 3, dataset.metadata.columns+1 ):
                base = dataset.metadata.flow_order[(i+1)%4]
                out.append( '<th>%d. %d %s</th>' % (i-2,base) )
            out.append('</tr>')
            out.append( self.make_html_peek_rows( dataset, skipchars=skipchars ) )
            out.append( '</table>' )
            out = "".join( out )
        except Exception, exc:
            out = "Can't create peek %s" % str( exc )
        return out

class Newick( Text ):
    """
    The Newick Standard for representing trees in computer-readable form makes use of the correspondence between trees and nested parentheses.
    http://evolution.genetics.washington.edu/phylip/newicktree.html
    http://en.wikipedia.org/wiki/Newick_format
    Example:
    (B,(A,C,E),D);
    or example with branch lengths:
    (B:6.0,(A:5.0,C:3.0,E:4.0):5.0,D:11.0);
    or an example with embedded comments but no branch lengths:
    ((a [&&PRIME S=x], b [&&PRIME S=y]), c [&&PRIME S=z]); 
    Example with named interior noe:
    (B:6.0,(A:5.0,C:3.0,E:4.0)Ancestor1:5.0,D:11.0);
    """
    file_ext = 'tre'

    def __init__(self, **kwd):
        Text.__init__( self, **kwd )

    def sniff( self, filename ):   ## TODO
        """
        Determine whether the file is in Newick format
        Note: Last non-space char of a tree should be a semicolon: ';'
        Usually the first char will be a open parenthesis: '('
        (,,(,));                               no nodes are named
        (A,B,(C,D));                           leaf nodes are named
        (A,B,(C,D)E)F;                         all nodes are named
        (:0.1,:0.2,(:0.3,:0.4):0.5);           all but root node have a distance to parent
        (:0.1,:0.2,(:0.3,:0.4):0.5):0.0;       all have a distance to parent
        (A:0.1,B:0.2,(C:0.3,D:0.4):0.5);       distances and leaf names (popular)
        (A:0.1,B:0.2,(C:0.3,D:0.4)E:0.5)F;     distances and all names
        ((B:0.2,(C:0.3,D:0.4)E:0.5)F:0.1)A;    a tree rooted on a leaf node (rare)
        """
        if not os.path.exists(filename):
            return False
        try:
            ## For now, guess this is a Newick file if it starts with a '(' and ends with a ';'
            flen = os.path.getsize(filename)
            fh = open( filename )
            len = min(flen,2000)
            # check end of the file for a semicolon
            fh.seek(-len,os.SEEK_END)
            buf = fh.read(len).strip()
            buf = buf.strip()
            if not buf.endswith(';'):
                return False
            # See if this starts with a open parenthesis
            if len < flen:
                fh.seek(0)
                buf = fh.read(len).strip()
            if buf.startswith('('):
                return True
        except:
            pass
        finally:
            close(fh)
        return False

class Nhx( Newick ):
    """
    New Hampshire eXtended  Newick with embedded 
    The Newick Standard for representing trees in computer-readable form makes use of the correspondence between trees and nested parentheses.
    http://evolution.genetics.washington.edu/phylip/newicktree.html
    http://en.wikipedia.org/wiki/Newick_format
    Example:
    (gene1_Hu[&&NHX:S=Hu_Homo_sapiens], (gene2_Hu[&&NHX:S=Hu_Homo_sapiens], gene2_Mu[&&NHX:S=Mu_Mus_musculus]));
    """
    file_ext = 'nhx'

class Nexus( Text ):
    """
    http://en.wikipedia.org/wiki/Nexus_file
    Example:
    #NEXUS
    BEGIN TAXA;
          Dimensions NTax=4;
          TaxLabels fish frog snake mouse;
    END;
    
    BEGIN CHARACTERS;
          Dimensions NChar=20;
          Format DataType=DNA;
          Matrix
            fish   ACATA GAGGG TACCT CTAAG
            frog   ACATA GAGGG TACCT CTAAG
            snake  ACATA GAGGG TACCT CTAAG
            mouse  ACATA GAGGG TACCT CTAAG
    END;
    
    BEGIN TREES;
          Tree best=(fish, (frog, (snake, mouse)));
    END;
    """
    file_ext = 'nex'

    def __init__(self, **kwd):
        Text.__init__( self, **kwd )

    def sniff( self, filename ):
        """
        Determines whether the file is in nexus format
        First line should be:
        #NEXUS
        """
        try:
            fh = open( filename )
            count = 0
            line = fh.readline()
            line = line.strip()
            if line and line == '#NEXUS':
                fh.close()
                return True
        except:
            pass
        finally:
            fh.close()
        return False

## Biom 

class BiologicalObservationMatrix( Text ):
    file_ext = 'biom'
    """
    http://biom-format.org/documentation/biom_format.html
    The format of the file is JSON:
    {
    "id":null,
    "format": "Biological Observation Matrix 0.9.1-dev",
    "format_url": "http://biom-format.org",
    "type": "OTU table",
    "generated_by": "QIIME revision 1.4.0-dev",
    "date": "2011-12-19T19:00:00",
    "rows":[
            {"id":"GG_OTU_1", "metadata":null},
            {"id":"GG_OTU_2", "metadata":null},
            {"id":"GG_OTU_3", "metadata":null},
        ],
    "columns": [
            {"id":"Sample1", "metadata":null},
            {"id":"Sample2", "metadata":null}
        ],
    "matrix_type": "sparse",
    "matrix_element_type": "int",
    "shape": [3, 2],
    "data":[[0,1,1],
            [1,0,5],
            [2,1,4]
           ]
    }

    """

    def __init__(self, **kwd):
        Text.__init__( self, **kwd )

    def sniff( self, filename ):
        if os.path.getsize(filename) < 50000:
            try:
                data = simplejson.load(open(filename))
                if data['format'].find('Biological Observation Matrix'):
                    return True
            except:
                pass
        return False




## Qiime Classes

class QiimeMetadataMapping(Tabular):
    MetadataElement( name="column_names", default=[], desc="Column Names", readonly=False, visible=True, no_value=[] )
    file_ext = 'qiimemapping'

    def __init__(self, **kwd):
        """
        http://qiime.sourceforge.net/documentation/file_formats.html#mapping-file-overview
        Information about the samples necessary to perform the data analysis. 
        # self.column_names = ['#SampleID','BarcodeSequence','LinkerPrimerSequence','Description']
        """
        Tabular.__init__( self, **kwd )

    def sniff( self, filename ):
        """
        Determines whether the file is a qiime mapping file
        Just checking for an appropriate header line for now, could be improved
        """
        try:
            pat = '#SampleID(\t[a-zA-Z][a-zA-Z0-9_]*)*\tDescription'
            fh = open( filename )
            while True:
                line = dataset_fh.readline()
                if re.match(pat,line):
                    return True
        except:
            pass
        finally:
            close(fh)
        return False

    def set_column_names(self, dataset):
        if dataset.has_data():
            dataset_fh = open( dataset.file_name )
            line = dataset_fh.readline()
            if line.startswith('#SampleID'):
                dataset.metadata.column_names = line.strip().split('\t');
            dataset_fh.close()

    def set_meta( self, dataset, overwrite = True, skip = None, max_data_lines = None, **kwd ):
        Tabular.set_meta(self, dataset, overwrite, skip, max_data_lines)
        self.set_column_names(dataset)

class QiimeOTU(Tabular):
    """
    Associates OTUs with sequence IDs
    Example:
    0	FLP3FBN01C2MYD	FLP3FBN01B2ALM
    1	FLP3FBN01DF6NE	FLP3FBN01CKW1J	FLP3FBN01CHVM4
    2	FLP3FBN01AXQ2Z
    """
    file_ext = 'qiimeotu'

class QiimeOTUTable(Tabular):
    """
        #Full OTU Counts
        #OTU ID	PC.354	PC.355	PC.356	Consensus Lineage
        0	0	1	0	Root;Bacteria;Firmicutes;"Clostridia";Clostridiales
        1	1	3	1	Root;Bacteria
        2	0	2	2	Root;Bacteria;Bacteroidetes
    """
    MetadataElement( name="column_names", default=[], desc="Column Names", readonly=False, visible=True, no_value=[] )
    file_ext = 'qiimeotutable'
    def init_meta( self, dataset, copy_from=None ):
        Tabular.init_meta( self, dataset, copy_from=copy_from )
    def set_meta( self, dataset, overwrite = True, skip = None, **kwd ):
        self.set_column_names(dataset) 
    def set_column_names(self, dataset):
        if dataset.has_data():
            dataset_fh = open( dataset.file_name )
            line = dataset_fh.readline()
            line = dataset_fh.readline()
            if line.startswith('#OTU ID'):
                dataset.metadata.column_names = line.strip().split('\t');
            dataset_fh.close()
            dataset.metadata.comment_lines = 2

class QiimeDistanceMatrix(Tabular):
    """
        	PC.354	PC.355	PC.356
        PC.354	0.0	3.177	1.955	
        PC.355	3.177	0.0	3.444
        PC.356	1.955	3.444	0.0
    """
    file_ext = 'qiimedistmat'
    def init_meta( self, dataset, copy_from=None ):
        Tabular.init_meta( self, dataset, copy_from=copy_from )
    def set_meta( self, dataset, overwrite = True, skip = None, **kwd ):
        self.set_column_names(dataset) 
    def set_column_names(self, dataset):
        if dataset.has_data():
            dataset_fh = open( dataset.file_name )
            line = dataset_fh.readline()
            # first line contains the names
            dataset.metadata.column_names = line.strip().split('\t');
            dataset_fh.close()
            dataset.metadata.comment_lines = 1

class QiimePCA(Tabular):
    """
    Principal Coordinate Analysis Data
    The principal coordinate (PC) axes (columns) for each sample (rows). 
    Pairs of PCs can then be graphed to view the relationships between samples. 
    The bottom of the output file contains the eigenvalues and % variation explained for each PC.
    Example:
    pc vector number	1	2	3
    PC.354	-0.309063936588	0.0398252112257	0.0744672231759
    PC.355	-0.106593922619	0.141125998277	0.0780204374172
    PC.356	-0.219869362955	0.00917241121781	0.0357281314115
    
    
    eigvals	0.480220500471	0.163567082874	0.125594470811
    % variation explained	51.6955484555	17.6079322939
    """
    file_ext = 'qiimepca'

class QiimeParams(Tabular):
    """
###pick_otus_through_otu_table.py parameters###

# OTU picker parameters
pick_otus:otu_picking_method    uclust
pick_otus:clustering_algorithm  furthest

# Representative set picker parameters
pick_rep_set:rep_set_picking_method     first
pick_rep_set:sort_by    otu
    """
    file_ext = 'qiimeparams'

class QiimePrefs(Text):
    """
    A text file, containing coloring preferences to be used by make_distance_histograms.py, make_2d_plots.py and make_3d_plots.py.
    Example:
{
'background_color':'black',

'sample_coloring':
        {
                'Treatment':
                {
                        'column':'Treatment',
                        'colors':(('red',(0,100,100)),('blue',(240,100,100)))
                },
                'DOB':
                {
                        'column':'DOB',
                        'colors':(('red',(0,100,100)),('blue',(240,100,100)))
                }
        },
'MONTE_CARLO_GROUP_DISTANCES':
        {
                'Treatment': 10,
                'DOB': 10
        }
}
    """
    file_ext = 'qiimeprefs'

class QiimeTaxaSummary(Tabular):
    """
        Taxon	PC.354	PC.355	PC.356
        Root;Bacteria;Actinobacteria	0.0	0.177	0.955	
        Root;Bacteria;Firmicutes	0.177	0.0	0.444
        Root;Bacteria;Proteobacteria	0.955	0.444	0.0
    """
    MetadataElement( name="column_names", default=[], desc="Column Names", readonly=False, visible=True, no_value=[] )
    file_ext = 'qiimetaxsummary'

    def set_column_names(self, dataset):
        if dataset.has_data():
            dataset_fh = open( dataset.file_name )
            line = dataset_fh.readline()
            if line.startswith('Taxon'):
                dataset.metadata.column_names = line.strip().split('\t');
            dataset_fh.close()

    def set_meta( self, dataset, overwrite = True, skip = None, max_data_lines = None, **kwd ):
        Tabular.set_meta(self, dataset, overwrite, skip, max_data_lines)
        self.set_column_names(dataset)

if __name__ == '__main__':
    import doctest, sys
    doctest.testmod(sys.modules[__name__])

