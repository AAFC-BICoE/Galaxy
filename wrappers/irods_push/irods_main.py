import sys
import irods_push_0_0_2
import os.path,time

#Set variables from command line
print "I got here"
directoryPath = sys.argv[1]
filePath = sys.argv[2]
fileName = sys.argv[3]
noclobber = sys.argv[4]
outputName = sys.argv[5]
historyContentId = sys.argv[6]
historyId = sys.argv[7]
outputExt = sys.argv[8]
toolId = sys.argv[9]
print "toolId: " + toolId
hostname = sys.argv[10]
port = sys.argv[11]
zone = sys.argv[12]
username = sys.argv[13] 
#missing sys.argv 14
password = os.environ['PASS']
metadataList = sys.argv[14]
resource = str(sys.argv[-1])

#set two lists containing the keys and values
#the minimal length of the command line arguement list is 17
if len(sys.argv) > 16 and sys.argv[14] != "blank":
	lenArgs = len(sys.argv)
	x = 14
	keys = []
	values = []
	while x < lenArgs-2:
		keys.append(sys.argv[x])
		values.append(sys.argv[x+1])
		x = x+2

#create object which will have irods session object.
newIrodsObject = irods_push_0_0_2.IrodsCredentials(hostname,port,zone,username,password,outputName)

#create new collection, if it doesn't already exist
newIrodsObject.addDirectories(directoryPath)

#add filepath to a list with only one item, only did this because I didn't want to rewrite 
#the irods_push functions
filePath = [filePath]

#same deal as for filename, the filename was put into a list because of previous implementation
#of irods_push functions
fileName = [fileName]

newIrodsObject.addFiles(filePath,fileName,directoryPath,noclobber,resource)

#add auto-generated metadata to a list to be added one by one, in this case we 
#have to define the key for these values.
listOfMeta = []
listOfMeta.append(toolId)
listOfMeta.append(historyContentId)
listOfMeta.append(historyId)
listOfMeta.append(outputExt)
creation_date = time.ctime(os.path.getctime(filePath[0]))
listOfMeta.append(creation_date)
listOfMeta.append(str(os.path.getsize(filePath[0])))

#add automatic defined metadata
newIrodsObject.addMetadata(fileName,directoryPath,listOfMeta)

#add user defined metadata
if 'keys' in locals():
	newIrodsObject.addMetadataFromList(fileName,directoryPath,keys,values)
