================
MrBayes Wrapper
================

MrBayes is a phylogenetics program. This wrapper makes it available in Galaxy.

The 'nooptsmb.xml' wrapper is for Nexus files which already have command blocks. It does not allow the user to specify options in the Galaxy interface. 

A sample input file is provided: ITS.nex

Two helpful papers are also included. 

Suggested imrpovements:
 - Read possible outgroups from the file and allow user to select from a dropdown menu
 - Add a check to ensure that the $data.ckp file exists if trying to append
 - Make relevant output files available in Galaxy (as text files, or specific datatype?)
