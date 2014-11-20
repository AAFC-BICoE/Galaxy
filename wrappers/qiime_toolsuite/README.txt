Installs QIIME fully in Galaxy.

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

Check the installation log for 'false' errors - sometimes it fails to download a package and you should try again.


