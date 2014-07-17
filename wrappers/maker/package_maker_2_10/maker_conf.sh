#!/bin/bash


##############
# Yue Liu, modified from script by Michael Li
# The other 2 config files (maker_opts.ctl, maker bopts.ctl)
# are taken care of in maker_conf.xml
# The paths here are set by tool_dependencies.xml
# genemark may or maynot be installed; if it is, it will be used
##############

cat $1 > $3;
cat $2 > $4;
maker -CTL ##maker automatically looks for the executables in PATH
cat maker_exe.ctl > $5;

: ' (all these stuff is commented out)
echo "\
#-----Location of Executables Used by MAKER/EVALUATOR
makeblastdb=${MAKERPATH}/dependencies/ncbi-blast-2.2.29+/bin/makeblastdb #location of NCBI+ makeblastdb executable
blastn=${MAKERPATH}/dependencies/ncbi-blast-2.2.29+/bin/blastn #location of NCBI+ blastn executable
blastx=${MAKERPATH}/dependencies/ncbi-blast-2.2.29+/bin/blastx #location of NCBI+ blastx executable
tblastx=${MAKERPATH}/dependencies/ncbi-blast-2.2.29+/bin/tblastx #location of NCBI+ tblastx executable
formatdb= #location of NCBI formatdb executable
blastall= #location of NCBI blastall executable
xdformat= #location of WUBLAST xdformat executable
blasta= #location of WUBLAST blasta executable
RepeatMasker=${MAKERPATH}/dependencies/RepeatMasker/RepeatMasker #location of RepeatMasker executable
exonerate=${MAKERPATH}/dependencies/exonerate-2.2.0-x86_64/bin/exonerate #location of exonerate executable

#-----Ab-initio Gene Prediction Algorithms
snap= ${MAKERPATH}/dependencies/snap/snap #location of snap executable
gmhmme3=`which gmhmme3` #location of eukaryotic genemark executable
gmhmmp= #location of prokaryotic genemark executable
augustus=${MAKERPATH}/dependencies/augustus-3.0.2/bin/augustus #location of augustus executable
fgenesh= #location of fgenesh executable

#-----Other Algorithms
fathom=${MAKERPATH}/dependencies/snap/fathom #location of fathom executable (experimental)
probuild=`which probuild` #location of probuild executable (required for genemark) \
" > $5 '
