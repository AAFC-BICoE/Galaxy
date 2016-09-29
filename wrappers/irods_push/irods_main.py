import sys
import irods_push_0_0_2
import getpass
#from galaxy import datatypes
import os.path,time
print " I got here"
#for now the assumption is that the user is using this tool in a linux environment
#sys.argv[1] is the directory path where the files will be placed, and sys.argv[-1] is the 'no clobber' flag.
#everything in between is file paths and file names
#pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
#envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"

#
#index = 1
#for arg in sys.argv:
#	print "index: " + str(index) + " Arg: " + arg
#	index = index+1
	

directoryPath = sys.argv[1]
print "argv1: " + directoryPath
filePath = sys.argv[2]
print "argv2: " + filePath
fileName = sys.argv[3]
print "argv3: " + fileName
noclobber = sys.argv[4]
print "argv4: " + noclobber
outputName = sys.argv[5]
print "argv5: " + outputName
historyContentId = sys.argv[6]
print "arg6: " + historyContentId
historyId = sys.argv[7]
print "arg7: " + historyId
outputExt = sys.argv[8]
print "argv8: " + outputExt
toolId = sys.argv[9] 
print "argv9: " + toolId
hostname = sys.argv[10]
print "argv10: " + hostname
port = sys.argv[11]
print "argv11: " + port
zone = sys.argv[12]
print "argv12: " + zone
username = sys.argv[13] 
print "arg13: " + username
password = sys.argv[14]
print "arg14: " + password
metadataList = sys.argv[15]
print "arg15: " + metadataList
resource = str(sys.argv[-1])
print "arg-1: " + resource
print "len: " + str(len(sys.argv))
if len(sys.argv) > 17 and sys.argv[15] != "blank":
	lenArgs = len(sys.argv)
	x = 15
	keys = []
	values = []
	while x < lenArgs-2:
		keys.append(sys.argv[x])
		values.append(sys.argv[x+1])
		x = x+2
	print "keys: " + str(keys)
	print "values: " + str(values)
#length by default is 17

#the last item will be the 'metadata' object
#11 with resource name I think...

newIrodsObject = irods_push_0_0_2.irodsCredentials(hostname,port,zone,username,password,outputName)
newIrodsObject.addDirectories(directoryPath)
filePath = [filePath]
fileName = [fileName]
#filePaths = []
#fileNames = []
#for x in range(2,len(sys.argv)-13,2):
	
#	filePaths.append(sys.argv[x])
#	fileNames.append(sys.argv[x+1])

newIrodsObject.addFiles(filePath,fileName,directoryPath,noclobber,resource)

listOfMeta = []

listOfMeta.append(toolId)
listOfMeta.append(historyContentId)
listOfMeta.append(historyId)
listOfMeta.append(outputExt)

creation_date = time.ctime(os.path.getctime(filePath[0]))
listOfMeta.append(creation_date)
listOfMeta.append(str(os.path.getsize(filePath[0])))

newIrodsObject.addMetadata(fileName,directoryPath,listOfMeta)
newIrodsObject.addMetadataFromList(fileName,directoryPath,keys,values)
