#!/usr/bin/env python
"""Convert a GFF and associated FASTA file into GenBank format.

Edited by: Michael Li, Feb 2014
Adapted from BCBB's script from github: https://github.com/chapmanb/bcbb/blob/master/gff/Scripts/gff/gff_to_genbank.py
Original Author: Brad Chapman 

Usage:
gff_to_genbank.py <GFF annotation file> [<fasta file>]

The output will share the same filename as the GFF annotation file, with a gb extension.
Provide a fasta file if there are no seqs at the end of the GFF3 file.
"""
import sys
import os

from Bio import SeqIO
from Bio.Alphabet import generic_dna
from Bio import Seq

from BCBio import GFF

def main(gff_file, fasta_file = None):
    # Use splitext to remove the extension of the original input file
    out_file = "%s.gb" % os.path.splitext(gff_file)[0]

    # Parser will differ slightly if fasta file is given
    if os.stat(gff_file) == 0 or ((fasta_file is not None) and os.stat(fasta_file)):
        print "ERROR: Empty file provided or cannot stat files"
        exit(64);
    elif fasta_file is None:
        gff_iter = GFF.parse(gff_file) #Parser/generator object
    else:
        fasta_input = SeqIO.to_dict(SeqIO.parse(fasta_file, "fasta", generic_dna)) # Process fasta file
        gff_iter = GFF.parse(gff_file, fasta_input) # Give fasta file to parser
    
    # One line to call all the checking function and to write in genbank format
    SeqIO.write(_check_gff(_fix_ncbi_id(gff_iter)), out_file, "genbank")

def _fix_ncbi_id(fasta_iter):
    """GenBank identifiers can only be 16 characters;
Use arbitrary naming system to ensure unique locus names.
Though SeqIO only uses rec.name to generate locus names, so we only need to change that.
Note that the contig # might not actually match the number of the actual contig. It depends on the file order.
"""
    #Generate unique IDs based on this.
    base = "Contig_" 
    count = 1
    for rec in fasta_iter:
        new_id = base + `count` #String concat
        rec.description = rec.id #Save the ID name so we know what it is. 
#        rec.id = new_id
	rec.name = new_id
        count += 1
	yield rec

def _check_gff(gff_iterator):
    """Check GFF files before feeding to SeqIO to be sure they have sequences.
"""
    for rec in gff_iterator:
        # We'd want to ensure that all contigs have the sequences attached to them properly.
        if isinstance(rec.seq, Seq.UnknownSeq):
            print "FATAL: FASTA sequence not found for '%s' in GFF file" % (
                    rec.id)
            exit(63);
        #Strangely, the seq alphabet is set to SingleLetterAlphabet by default.
        rec.seq.alphabet = generic_dna
        yield _flatten_features(rec)

def _flatten_features(rec):
    """Make sub_features in an input rec flat for output.

GenBank does not handle nested features, so we want to make
everything top level.

No idea what happens here... (Michael)
"""
    out = []
    for f in rec.features:
        cur = [f]
        while len(cur) > 0:
            nextf = []
            for curf in cur:
                out.append(curf)
                if len(curf.sub_features) > 0:
                    nextf.extend(curf.sub_features)
            cur = nextf
    rec.features = out
    return rec

if __name__ == "__main__":
    main(*sys.argv[1:])
