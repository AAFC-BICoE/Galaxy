#!/bin/bash

## By Michael Li, Feb 2014.
## This script is the wrapper for MAKER v2.10 in Galaxy. 
## This script should not be called on directly except from maker.xml and the inputs should be as follows.
## maker_wrap.sh <genome_file> <maker_exe.ctl> <maker_opts.ctl> <maker_bopts.ctl> 
##      $5-$8	 <datastore_output_handle> <gff_output_handle> <output_transcripts> <output_proteins>
##	$9	 <output_other_transcripts | "empty"> 
##	$10	 <output_other_proteins | "empty">
##	$11	 <gff_reannotate | "empty"> 
##	$12	 <est | "empty"> 
##	$13	 <est_gff | "empty">
##	$14	 <altest | "empty"> 
##	$15	 <altest_gff | "empty">
##	$16	 <protein | "empty"> 
##	$17	 <protein_gff | "empty">
##	$18	 <snaphmm file | "empty"> 
##	$19	 <genemark | "empty"> 
##	$20	 <augustus | "empty"> 
##	$21	 <fgenesh | "empty">
##	$22	 <other preds | "empty"> 
##	$23	 <other gene models | "empty"> 
##	$24	 <other features | "empty">
##	$25	 <repeat library | "empty">
##	$26	 <repeat protein | "empty">
##	$27	 <rm_gff | "empty">

#Rename files
cp $1 genome.fasta || { echo "Unable to rename the contig file"; exit 113; }
cp $2 maker_exe.ctl || { eval echo "Unable to rename the maker_exe file"; exit 113;  }
cp $3 maker_opts.ctl || { eval echo "Unable to rename the maker_opts file"; exit 113; }
cp $4 maker_bopts.ctl || { eval echo "Unable to rename the maker_bopts file"; exit 113; }

##Substute all evidence and data files into control files
#Genome file
sed -i s%^genome=.*%genome=genome.fasta% maker_opts.ctl
#reannotation GFF file
if [ "${11}" != "empty" ]; then 
	sed -i s%^genome_gff=.*%genome_gff=${11}% maker_opts.ctl
fi
#EST evidence
if [ "${12}" != "empty" ]; then
	sed -i s%^est=.*%est=${12}% maker_opts.ctl
fi
#EST GFF evidence
if [ "${13}" != "empty" ]; then
	sed -i s%^est_gff=.*%est_gff=${13}% maker_opts.ctl
fi
#ALTEST evidence
if [ "${14}" != "empty" ]; then
	sed -i s%^altest=.*%altest=${14}% maker_opts.ctl
fi
#ALTEST GFF evidence
if [ "${15}" != "empty" ]; then
	sed -i s%^altest_gff=.*%altest_gff=${15}% maker_opts.ctl
fi
#Protein evidence
if [ "${16}" != "empty" ]; then
	sed -i s%^protein=.*%protein=${16}% maker_opts.ctl
fi
#Protein GFF evidence
if [ "${17}" != "empty" ]; then
	sed -i s%^protein_gff=.*%protein=${17}% maker_opts.ctl
fi
#SNAP File
if [ "${18}" != "empty" ]; then
	sed -i s%^snaphmm=.*%snaphmm=${18}% maker_opts.ctl
fi
#Genemark File
if [ "${19}" != "empty" ]; then
	sed -i s%^gmhmm=.*%gmhmm=${19}% maker_opts.ctl
fi
#Augustus Species Model
if [ "${20}" != "empty" ]; then
	sed -i s%^augustus_species=.*%augustus_species=${20}% maker_opts.ctl
fi
#FGENESH parameter file
if [ "${21}" != "empty" ]; then
	sed -i s%^fgenesh_par_file=.*%fgenesh_par_file=${21}% maker_opts.ctl
fi
#Other Predictions
if [ "${22}" != "empty" ]; then
	sed -i s%^pred_gff=.*%pred_gff=${22}% maker_opts.ctl
fi
#Other Gene Models
if [ "${23}" != "empty" ]; then
	sed -i s%^model_gff=.*%model_gff=${23}% maker_opts.ctl
fi
#Other Features
if [ "${24}" != "empty" ]; then
	sed -i s%^other_gff=.*%other_gff=${24}% maker_opts.ctl
fi
#Repeat Library
if [ "${25}" != "empty" ]; then
	sed -i s%^rmlib=.*%rmlib=${25}% maker_opts.ctl
fi
#Repeat Protein Sequences
if [ "${26}" != "empty" ]; then
	sed -i s%^repeat_protein=.*%repeat_protein=${26}% maker_opts.ctl
fi
if [ "${27}" != "empty" ]; then
	sed -i s%^rm_gff=.*%rm_gff=${27}% maker_opts.ctl
fi

#Force cpu to be 1
sed -i s%^cpus=.*%cpus=1% maker_opts.ctl
#Set tmp folder to prevent NFS errors.
sed -i s%^TMP=.*%TMP=/state/partition1/% maker_opts.ctl

#These files can be sourced so we can validate the input.
#. maker_exe.ctl 
#. maker_bopts.ctl
#. maker_opts.ctl

#Check if all evidence files are valid and exist
#if [ $genome_gff ]; then

maker 2>&1 || { echo "MAKER has run ino an error. Aborting."; exit 114; }

#Get files from datastore
cd genome.maker.output
fasta_merge -d genome_master_datastore_index.log
gff3_merge -d genome_master_datastore_index.log


##Paste results to awaiting output files
cat genome_master_datastore_index.log >> $5
cat genome.all.gff >> $6
cat genome.all.maker.transcripts.fasta >> $7 || echo "No annotations available for one contig" 1>&2
cat genome.all.maker.proteins.fasta >> $8

##Save unused predictions
if [ "$9" != "empty" -a "${10}" != "empty" ]; then
	#SNAP
	if [ "${18}" != "empty" ]; then
		cat genome.all.maker.snap.transcripts.fasta >> $9 || echo "No unused snap transcripts" 1>&2
                cat genome.all.maker.snap.proteins.fasta >> ${10} || echo "No unused snap proteins" 1>&2

		cat genome.all.maker.snap_masked.transcripts.fasta >> $9 || echo "No unused masked snap transcripts" 1>&2
		cat genome.all.maker.snap_masked.proteins.fasta >> ${10} || echo "No unused masked snap proteins" 1>&2
	fi
	#GeneMark
	if [ "${19}" != "empty" ]; then
		cat genome.all.maker.genemark.transcripts.fasta >> $9 || echo "No unused genemark transcripts" 1>&2
                cat genome.all.maker.genemark.proteins.fasta >> ${10} || echo "No unused genemark proteins" 1>&2
		cat genome.all.maker.genemark_masked.transcripts.fasta >> $9 || echo "No unused masked genemark transcripts" 1>&2
		cat genome.all.maker.genemark_masked.proteins.fasta >> ${10} || echo "No unused masked genemark proteins" 1>&2
	fi
	#Augustus
	if [ "${20}" != "empty" ]; then 
		cat genome.all.maker.augustus_masked.transcripts.fasta >> $9 || echo "No unused masked augustus transcripts" 1>&2
                cat genome.all.maker.augustus_masked.proteins.fasta >> ${10} || echo "No unused masked augustus proteins" 1>&2
		cat genome.all.maker.augustus.transcripts.fasta >> $9 || echo "No unused augustus transcripts" 1>&2
		cat genome.all.maker.augustus.proteins.fasta >> ${10} || echo "No unused augustus proteins" 1>&2
	fi
	#FGENESH
	if [ "${21}" != "empty" ]; then
		cat genome.all.maker.fgenesh.transcripts.fasta >> $9 || echo "No unused fgenesh transcripts" 1>&2
                cat genome.all.maker.fgenesh.proteins.fasta >> ${10} || echo "No unused fgenesh proteins" 1>&2
		cat genome.all.maker.fgenesh_masked.transcripts.fasta >> $9 || echo "No unused masked fgenesh transcripts" 1>&2
		cat genome.all.maker.fgenesh_masked.proteins.fasta >> ${10} || echo "No unused masked fgenesh proteins" 1>&2
	fi
fi

