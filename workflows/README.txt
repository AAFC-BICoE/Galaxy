These workflows can be imported into Galaxy: from the Galaxy web interface, click on Workflow from the top navigation bar, and then click the "Upload or import workflow" button in the top right-hand corner. 

Running workflows:

To run the "Select random subset" workflows, you need any input FASTA file. You can specify how many sequences (n) to keep from the FASTA file, where n <= the number of sequences in the file. If you choose to set a seed, you can re-use this number to produce the same (pseudo-random) set of sequences. This can be useful for testing purposes. 

To run the "Fungi QC" worfklow, you should have something like all fungal ITS sequences from GenBank; an example, fungalQC_input.fasta is included. You should ensure that the two LCA analysis steps (#10 and 11) specify the same number of sequences to ignore. 

Note: the FQC workflow is still a work in progress. Suggested improvements include:
 - Review the logic behind the clustering/LCA analyses with some scientists
 - For the LCA, use a percentage to ignore (instead of a fixed number)
 - Ignore x taxa (instead of x sequences)
 - List LCA rank for clusters with LCA > genus
 - List genera in  each cluster
 - Determine the number of clusters per taxa
 - Deal with synonymous organisms (or non-specific names, like "fungal sp ...")

