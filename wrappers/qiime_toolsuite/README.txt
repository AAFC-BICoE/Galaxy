Installs QIIME fully in Galaxy
==============================

Note the tool dependencies does not install the following:
    freetype (libfreetype6-dev)
    g++
    gcc 
    bz2 (Should be included in python)
    python2.7+ (2.7.8 works, but needs 2.7.3+)
    libpng-dev
    libblas-dev
    liblapack-dev
    gfortran
Most of these are common packages found in linux-type environments, but check beforehand.

This package also uses XML tools generated from the qiime-galaxy repository, in addition sourcing several of their scripts. This is handled through tool dependency. 

Check the installation log for 'false' errors - sometimes it fails to download a package and you should try again. The dependency is prone to failing due to the numerous steps.

Galaxy will emulate the current version of python on your system. It is recommended to either install python 2.7.3+, or use a virutal env beforehand.

## Tool Output

At the moment, the XML files are not optimized and generate TGZ files as output. If you need to pipe the output of one file as input of another, you need to re-upload the contents of the TGZ to Galaxy.

