import sys
import irods_push_0_0_2
import getpass
#for now the assumption is that the user is using this tool in a linux environment
#sys.argv[1] is the directory path where the files will be placed, and sys.argv[-1] is the 'no clobber' flag.
#everything in between is file paths and file names
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"

newIrodsObject = irods_push_0_0_2.irodsCredentials(envFile,pwFile,sys.argv[-1])

newIrodsObject.addDirectories(sys.argv[1])

filePaths = []
fileNames = []
for x in range(2,len(sys.argv)-3,2):
	filePaths.append(sys.argv[x])
	fileNames.append(sys.argv[x+1])
newIrodsObject.addFiles(filePaths,fileNames,sys.argv[1],sys.argv[-2])

