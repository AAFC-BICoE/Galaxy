#!/bin/bash

source_in=$1;
shift;
gff_in=$1;
shift;
species_in=$1;
shift;
genome_in=$1;
shift;
out_file=$1;

mkdir trainaugtmp;
cd trainaugtmp;
if [ "$source_in" == maker ]; then
	maker2zff $gff_in ;
else
	cegma2zff $gff_in $genome_in;
	cegma2gff.pl $gff_in > aug_trainable.gff;
	gff_in=aug_trainable.gff;
fi

gff2gbSmallDNA.pl $gff_in genome.dna 1000 genes.gb;
autoAugTrain.pl --trainingset=genes.gb --species=$species_in;
RESULT=${?};

cd ..;


if [ ${RESULT} -eq 0 ]; then
	echo "Training for $species_in finished successfully" >> $out_file; true;
else
	echo "Training for $species_in failed" > $out_file; false;
fi

#====== debug info here ======
echo "Exit status returned: $RESULT" >> $out_file;
#ls "trainaugtmp/" >> $out_file;
#cat "trainaugtmp/genes.gb" >> $out_file;
#======    end debug    ======

rm -r trainaugtmp;
exit $RESULT;
