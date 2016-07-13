Things to note:
Make sure you have the python-irodsclient api installed in your galaxy instance before installation.
Link: https://github.com/irods/python-irodsclient

Authentication:
This is a work in progress. For now the tool assumes you have access to .irodsA and irods_environment.json files which get 
created from logging into irods using the icommands. I am still looking for a better to authenticate against irods in the 
galaxy environment.

There are two options for importing files:

-using an absolute file path (shared file path option, looking for better name for this)
-getting existing file paths based on directory name typed so far. Ex if I have files in /tempZone/home/rods/ and that is what
I type in the directory location, I will get all the files in this directory. You can only list files in directories you
have read permissions.

Author: Katherine Beaulieu
