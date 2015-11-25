# **PhyML Galaxy Wrapper** <br>
This repository contains a Galaxy tool wrapper for the PhyML program, which estimates the maximum likelihood phylogenies from alignments of nucleotide or amino acid sequences. <br>
PhyML has been developed within the PhyML Development Team at ATGC Montpellier Bioinformatics platform. (*http://www.atgc-montpellier.fr/phyml/*)

The reference for PhyML is: <br>
	<pre>*New Alogirthms and Methods to Estimate Maximum-Likelihood Phylogenies: Assessing the Performance of PhyML* 
Guindon S., Dufayard J.F., Lefort V., Anisimova M., Hordijk W., & Gascuel O. (2010). 3.0. 
System Biology, 59(3):307-21. </pre>

The PhyML Tool Suite repository: <br>
<pre>* Provides PhyML wrapper for the PhyML tool 
* Downloads and installs PhyML on the Linux operating system  </pre>

How to Check Out the Repository? <br>
<pre>Clone it!
$ git clone -b phyml --single-branch https://github.com/AAFC-MBB/Galaxy.git </pre>

##**Automated Installation** <br>
The Tool Shed allows you to create repositories, and lets you select files from your local file system and upload them to the repositories. Once they are uploaded on your local Tool Shed, you can install the repositories into your local Galaxy instance.<br>

###Steps
1. Start your local Galaxy and Galaxy Tool Shed. <br>
2. How to create repositories and upload the files on local Toolshed? <br>
	* Create a category on Toolshed and call it PhyML. <br>
	* In the PhyML category, create two repositories: <br>
		<pre>Name: phyml, Type: Unristricted Repository 
Name: package_phyml, Type: Tool Dependency Repository </pre>
	* For the package_phyml repository, upload the file tool_dependencies.xml, located in wrappers/PhyML/package_phyml. This file will take care of installing PhyML. <br>
	* For the phyml repository, some changes must be made to the wrappers/PhyML/phyml/tool_dependencies.xml before uploading any file. <br>
	<pre>Change the toolshed attribute to match your hostname: 
		&lt;repository name="package_phyml owner="galaxyuser" toolshed="http://yourmachinename.agr.gc.ca:9009"> </pre>
	* Now, upload wrappers/PhyML/phyml/phyml_wrapper.xml and wrappers/PhyML/phyml/tool_dependencies.xml to the phyml repository. <br>
3. How to install the repositories on local Galaxy? 
	* Go to your local Galaxy instance, click on "Admin", then on "Search and Browse Tool Sheds". <br>
	* Click on "Local Tool Shed", and then click on "PhyML". <br>
	* Click on "phyml", then "Preview and Install". This will take care of installing the PhyML tool as well as the PhyML wrapper. <br>
	* Finally, click on "Install to Galaxy". <br>
	* You can now run the tool. <br>

## **Manual Installation**
There are two files to install: 
<pre>* phyml_wrapper.xml (Galaxy Wrapper)
* phyml (the binaries for the PhyML Tool) </pre>
The suggested location is in a tools/phyml/ folder. 

###Steps 
1. How to get the wrapper?
<pre>$ cd tools
$ mkdir phyml
$ cd phyml
$ wget https://raw.githubusercontent.com/AAFC-MBB/Galaxy/phyml/wrappers/PhyML/phyml/phyml_wrapper.xml </pre>
2. How to get the binaries?
<pre>$ cd tools/phyml
$ wget http://www.atgc-montpellier.fr/download/binaries/phyml/PhyML-3.1.zip
$ unzip PhyML-3.1.zip
$ cd PhyML-3.1
$ mv PhyML-3.1_linux64 phyml
$ mv phyml ../ 
$ cd ..
$ rm -r PhyML-3.1
$ rm -r PhyML-3.1_linux64
$ chmod 755 phyml </pre>
3. Add this to the command section in the PhyML Wrapper, so that Galaxy can locate the phyml binaries:
<pre>&lt;command>
filename=./`basename $seq_file_name` &&
cp $seq_file_name \$filename &&
/galaxy/tools/phyml/phyml -i \$filename ...
&lt;command>
4. Then, modify the tool_conf.xml and tool_conf.xml.sample files to tell Galaxy about the new tool:
<pre>&lt;section id="phyml" name="Phylogeny Maximum Likelihood" >
    &lt;tool file="phyml/phyml_wrapper.xml" />
&lt;/section> </pre>
5. Don't forget to restart Galaxy! 
