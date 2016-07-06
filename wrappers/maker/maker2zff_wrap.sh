#!/bin/bash

output_ann=$1;
shift;
output_dna=$1;
shift;

maker2zff $@;

cat genome.ann > $output_ann;
cat genome.dna > $output_dna;
