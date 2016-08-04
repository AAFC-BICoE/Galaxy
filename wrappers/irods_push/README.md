Things to note: Make sure you have the python-irodsclient api installed in your galaxy instance before installation.
Link: https://github.com/irods/python-irodsclient

Authentication: This is a work in progress. For now the tool assumes you have access to .irodsA and irods_environment.json 
files which get created from logging into irods using the icommands. I am still looking for a better to authenticate against 
irods in the galaxy environment.

There are two options for Exporting files:

-using an absolute directory path (, looking for better name for this) 
-getting existing directory paths based on directory depth typed so far based on your user home directory. The user home
directory generally looks like this: <yourzone>/home/<yourusername>. If I were to type in a directory depth of 1, I would get 
just the user home directory, depth of 2 is all the directories within the user home directory and the user home directory and it
goes on like that.

Coming next: Better authentication method, replacement of deprecated code file tag

Author: Katherine Beaulieu
