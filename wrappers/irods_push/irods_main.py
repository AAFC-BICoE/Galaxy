import sys
import irods_push_0_0_2
import getpass
#from galaxy import datatypes
import os.path,time
print " I got here"
#for now the assumption is that the user is using this tool in a linux environment
#sys.argv[1] is the directory path where the files will be placed, and sys.argv[-1] is the 'no clobber' flag.
#everything in between is file paths and file names
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"


index = 1
for arg in sys.argv:
	print "index: " + str(index) + " Arg: " + arg
	index = index+1



#the last item will be the 'metadata' object
#11 with resource name I think...
totalLengthArgs = len(sys.argv)
if totalLengthArgs < 17:
	sys.argv.append("blank")
#print "Last argument: " + sys.argv[-1]

newIrodsObject = irods_push_0_0_2.irodsCredentials(sys.argv[-6],sys.argv[-5],sys.argv[-4],sys.argv[-3],sys.argv[-2],sys.argv[-12])
#newIrodsObject.checkIfCollectionExists(sys.argv[1])
newIrodsObject.addDirectories(sys.argv[1])

filePaths = []
fileNames = []
for x in range(2,len(sys.argv)-13,2):
	
	filePaths.append(sys.argv[x])
	fileNames.append(sys.argv[x+1])

newIrodsObject.addFiles(filePaths,fileNames,sys.argv[1],sys.argv[-13],sys.argv[-1])

listOfMeta = []

listOfMeta.append(sys.argv[-11])
listOfMeta.append(sys.argv[-10])
listOfMeta.append(sys.argv[-9])
listOfMeta.append(str(sys.argv[-8]))

creation_date = time.ctime(os.path.getctime(filePaths[0]))
listOfMeta.append(creation_date)
listOfMeta.append(str(os.path.getsize(filePaths[0])))

newIrodsObject.addMetadata(fileNames,sys.argv[1],listOfMeta)
