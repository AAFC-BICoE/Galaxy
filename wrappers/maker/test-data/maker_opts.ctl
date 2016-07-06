#-----Genome (Required for De-Novo Annotation)
genome=genome.fasta #genome sequence file in fasta format
organism_type=eukaryotic #eukaryotic or prokaryotic. Default is eukaryotic

#-----Re-annotation Using MAKER Derived GFF3
genome_gff= #re-annotate genome based on this gff3 file
est_pass=0 #use ests in genome_gff: 1 = yes, 0 = no
altest_pass=0 #use alternate organism ests in genome_gff: 1 = yes, 0 = no
protein_pass=0 #use proteins in genome_gff: 1 = yes, 0 = no
rm_pass=0 #use repeats in genome_gff: 1 = yes, 0 = no
model_pass=0 #use gene models in genome_gff: 1 = yes, 0 = no
pred_pass=0 #use ab-initio predictions in genome_gff: 1 = yes, 0 = no
other_pass=0 #passthrough everything else in genome_gff: 1 = yes, 0 = no

#-----EST Evidence (for best results provide a file for at least one)
est=est.fasta #non-redundant set of assembled ESTs in fasta format (classic EST analysis)
est_reads= #unassembled nextgen mRNASeq in fasta format (not fully implemented)
altest= #EST/cDNA sequence file in fasta format from an alternate organism
est_gff= #EST evidence from an external gff3 file
altest_gff= #Alternate organism EST evidence from a separate gff3 file

#-----Protein Homology Evidence (for best results provide a file for at least one)
protein=protein.fasta  #protein sequence file in fasta format
protein_gff=  #protein homology evidence from an external gff3 file

#-----Repeat Masking (leave values blank to skip repeat masking)
model_org=all #select a model organism for RepBase masking in RepeatMasker
rmlib= #provide an organism specific repeat library in fasta format for RepeatMasker
repeat_protein=/isilon/biodiversity/pipelines/maker-2.10/maker-2.10/data/te_proteins.fasta #provide a fasta file of transposable element proteins for RepeatRunner
rm_gff= #repeat elements from an external GFF3 file
prok_rm=0 #forces MAKER to run repeat masking on prokaryotes (don't change this), 1 = yes, 0 = no

#-----Gene Prediction
snaphmm=snap.hmm #SNAP HMM file
gmhmm= #GeneMark HMM file
augustus_species=human #Augustus gene prediction species model
fgenesh_par_file= #Fgenesh parameter file
pred_gff= #ab-initio predictions from an external GFF3 file
model_gff= #annotated gene models from an external GFF3 file (annotation pass-through)
est2genome=0 #infer gene predictions directly from ESTs, 1 = yes, 0 = no
protein2genome=0 #gene prediction from protein homology (prokaryotes only), 1 = yes, 0 = no
unmask=0 #Also run ab-initio prediction programs on unmasked sequence, 1 = yes, 0 = no

#-----Other Annotation Feature Types (features MAKER doesn't recognize)
other_gff= #features to pass-through to final output from an extenal GFF3 file

#-----External Application Behavior Options
alt_peptide=C #amino acid used to replace non standard amino acids in BLAST databases
cpus=1 #max number of cpus to use in BLAST and RepeatMasker (not for MPI, leave 1 when using MPI)

#-----MAKER Behavior Options
max_dna_len=100000 #length for dividing up contigs into chunks (increases/decreases  memory usage)
min_contig=1 #skip genome contigs below this length (under 10kb are often useless)

pred_flank=200 #flank for extending evidence clusters sent to gene predictors
AED_threshold=1 #Maximum Annotation Edit Distance allowed (bound by 0 and 1)
min_protein=0 #require at least this many amino acids in predicted proteins
alt_splice=0 #Take extra steps to try and find alternative splicing, 1 = yes, 0 = no
always_complete=0 #force start and stop codon into every gene, 1 = yes, 0 = no
map_forward=0 #map names and attributes forward from old GFF3 genes, 1 = yes, 0 = no
keep_preds=0 #Add unsupported gene prediction to final annotation set, 1 = yes, 0 = no

split_hit=10000 #length for the splitting of hits (expected max intron size for evidence alignments)
softmask=1 #use soft-masked rather than hard-masked (seg filtering for wublast)
single_exon=0 #consider single exon EST evidence when generating annotations, 1 = yes, 0 = no
single_length=250 #min length required for single exon ESTs if 'single_exon is enabled'

retry=1 #number of times to retry a contig if there is a failure for some reason
clean_try=0 #remove all data from previous run before retrying, 1 = yes, 0 = no
clean_up=0 #removes theVoid directory with individual analysis files, 1 = yes, 0 = no
TMP= #specify a directory other than the system default temporary directory for temporary files

#-----EVALUATOR Control Options
evaluate=0 #run EVALUATOR on all annotations (very experimental), 1 = yes, 0 = no
side_thre=5
eva_window_size=70
eva_split_hit=1
eva_hspmax=100
eva_gspmax=100
enable_fathom=0
