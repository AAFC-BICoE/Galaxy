import sys
import irods_push_0_0_2
import getpass
#from galaxy import datatypes
import os.path,time
#for now the assumption is that the user is using this tool in a linux environment
#sys.argv[1] is the directory path where the files will be placed, and sys.argv[-1] is the 'no clobber' flag.
#everything in between is file paths and file names
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"


#the last item will be the 'metadata' object
#11 with resource name I think...
totalLengthArgs = len(sys.argv)
if totalLengthArgs < 11:
	sys.argv.append("blank")
print "Last argument: " + sys.argv[-1]

newIrodsObject = irods_push_0_0_2.irodsCredentials(envFile,pwFile,sys.argv[-6])
#newIrodsObject.checkIfCollectionExists(sys.argv[1])
newIrodsObject.addDirectories(sys.argv[1])

filePaths = []
fileNames = []
for x in range(2,len(sys.argv)-8,2):
#	print sys.argv[x+1]	
	filePaths.append(sys.argv[x])
	fileNames.append(sys.argv[x+1])
newIrodsObject.addFiles(filePaths,fileNames,sys.argv[1],sys.argv[-7],sys.argv[-1])
#print filePaths
#print fileNames
#print sys.argv[1]
#print sys.argv[-4]
#print "Password: " + str(sys.argv[-1])
print "Resource Name: " + str(sys.argv[-1])
listOfMeta = []
#sys.argv[-1] is the tool_id
listOfMeta.append(sys.argv[-5])
listOfMeta.append(sys.argv[-4])
listOfMeta.append(sys.argv[-3])
listOfMeta.append(str(sys.argv[-2]))
#print "Trying to print uuid: " + str(sys.argv[-1])
print str(filePaths)
creation_date = time.ctime(os.path.getctime(filePaths[0]))
listOfMeta.append(creation_date)
listOfMeta.append(str(os.path.getsize(filePaths[0])))
#listOfMeta.append(sys.argv[-1])
newIrodsObject.addMetadata(fileNames,sys.argv[1],listOfMeta)
