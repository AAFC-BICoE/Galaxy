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


### **Automated Installation** <br>
Installation via the Galaxy Tool Shed will take care of installing the tool wrapper, and the phyml program. <br>
	1. Start your local Galaxy and Galaxy Toolshed. <br>
	2. Create a category on Toolshed and call it PhyML. <br>
	3. In the PhyML category, create two repositories: <br>
		<pre>Name: phyml, Type: Unristricted Repository 
Name: package_phyml_3_1, Type: Tool Dependency Repository </pre>

</pre>	4. For the package_phyml_3_1 repository, upload the file tool_dependencies.xml (located in wrappers/PhyML/package_phyml_3_1). This file wile will take care of installing PhyML. <br>
	5. For the phyml repository, some changes must be made to the wrappers/PhyML/phyml/tool_dependencies.xml before uploading any file. <br>
	<pre>*Change the toolshed attribute to match your hostname: 
		&lt;repository name="package_phyml_3_1 owner="galaxyuser" toolshed="http://yourmachinename.agr.gc.ca:9009"  ... >
*Change the changeset_revision to match the revision of the package_phyml_3_1 repository
		&lt;repository name="package_phyml_3_1 owner="galaxyuser" toolshed="http://yourmachinename.agr.gc.ca:9009" changeset_revision="revision of package_phyml_3_1" > </pre>

</pre>  6. Now, upload wrappers/PhyML/phyml/phyml_wrapper.xml and wrappers/PhyML/phyml/tool_dependencies.xml to the phyml repository.
	7. Go to your local Galaxy instance, click on Admin, then on Search and Browse Tool Sheds. Next, click on PhyML, and you can now install PhyML and run the tool.

### **Manual Installation**
There are two files to install: 
<pre>* phyml_wrapper.xml (Galaxy Wrapper)
* phyml (the binaries for the PhyML Tool) </pre>

The suggested location is in a tools/phyml/ folder. 

How to get the wrapper?
<pre>1. cd tools
2. mkdir phyml
3. cd phyml
4. wget https://raw.githubusercontent.com/AAFC-MBB/Galaxy/phyml/wrappers/PhyML/phyml/phyml_wrapper.xml </pre>

How to get the binaries?
<pre>1. cd tools/phyml
2. wget http://www.atgc-montpellier.fr/download/binaries/phyml/PhyML-3.1.zip
3. unzip PhyML-3.1.zip
4. rm <all the files in PhyML-3.1 except PhyML-3.1_linux64>
5. mv PhyML-3.1_linux64 phyml
6. mv phyml ../ 
7. cd ...
8. rm -r PhyML-3.1
9. chmod 755 phyml </pre>

Then, modify the tools_conf.xml and tools_conf.xml.sample files to tell Galaxy about the new tool:
<pre> &lt;section id="phyml" name="Phylogeny Maximum Likelihood" >
    &lt;tool file="phyml/phyml_wrapper.xml" />
&lt;/section> </pre>

Don't forget to restart Galaxy!

