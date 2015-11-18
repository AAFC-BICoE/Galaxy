# PhyML Galaxy Wrapper

This repository contains a Galaxy tool wrapper for the PhyML program, which estimates the maximum likelihood phylogenies from alignments of nucleotide or amino acide sequences. 

PhyML has been developed within the PhyML Development Team at ATGC Montpellier Bioinformatics platform (http://www.atgc-montpellier.fr/phyml/)

The reference for PhyML is:
	- Guindon S., Dufayard J.F., Lefort V., Anisimova M., Hordijk W., & Gascuel O. (2010). New Alogirthms and Methods to Estimate Maximum-Likelihood Phylogenies: Assessing the Performance of PhyML 3.0. System Biology, 59(3):307-21.

The PhyML Tool Suite repository:
	- Provides PhyML wrapper for the PhyML tool
	- Downloads and installs PhyML on the Linux operating system

Requirements:
	- Virtual Machine
	- Galaxy
	- Galaxy Tool Shed
	- Linux 



Automated Installation
Installation via the Galaxy Tool Shed will take care of installing the tool wrapper, and the phyml program. 

1- Start your virtual environment

2- Create a category on your local Tool Shed called PhyML

3- In that category, you need to create two repositories on your local Tool Shed:
	- Name: phyml, Type: Unristricted Repository
	- Name: package_phyml_3_1, Type: Tool Dependency Repository

4- For the repository package_phyml_3_1, you need to upload the file tool_dependencies.xml (located in wrappers/PhyML/package_phyml_3_1). This file wile will take care of installing PhyML.

5- For the repository phyml, you need to upload two files called phyml_wrapper.xml and tool_dependencies.xml (located in wrappers/PhyML/phyml). But before you upload these files, some changes must be made for the wrappers/PhyML/phyml/tool_dependencies.xml. 
	- Change the toolshed attribute to match your hostname
		<repository name="package_phyml_3_1 owner="galaxyuser" toolshed="http://yourmachinename.agr.gc.ca:9009" ... />

	- Change the changeset_revision to match the revision of the package_phyml_3_1 repository
		<repository name="package_phyml_3_1 owner="galaxyuser" toolshed="http://yourmachinename.agr.gc.ca:9009" changeset_revision="revision of package_phyml_3_1" />
	

6- Go to your local Galaxy instance, Admin -> Search and Browse Tool Sheds -> Local Tool Shed -> PhyML. You can now install PhyML and run the tool. 



Manual Installation
There are two files to install:
	- phyml_wrapper.xml (Galaxy Wrapper)
	- phyml (the binaries for the PhyML Tool)

The suggested location is in a tools/phyml/ folder. 

How to get the wrapper?
1. cd tools
2. mkdir phyml
3. cd phyml
4. wget https://raw.githubusercontent.com/AAFC-MBB/Galaxy/phyml/wrappers/PhyML/phyml/phyml_wrapper.xml

How to get the binaries?
1. cd tools/phyml
2. wget http://www.atgc-montpellier.fr/download/binaries/phyml/PhyML-3.1.zip
3. unzip PhyML-3.1.zip
4. rm <everything except PhyML-3.1_linux64>
5. mv PhyML-3.1_linux64 phyml
6. mv phyml ../ 

You will then need to modify the tools_conf.xml file to tell Galaxy to offer the tool by adding the following:
<section id="phyml" name="Phylogeny Maximum Likelihood">
    <tool file="phyml/phyml_wrapper.xml" />
</section> 

Don't forget to restart Galaxy!

			




