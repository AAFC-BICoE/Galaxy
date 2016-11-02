import sys
import irods_push_0_0_2
import os.path,time
import argparse


def main():
	parser = argparse.ArgumentParser(description='Process export tool parameters')
	parser.add_argument('-d', '--dirPath', dest='dirPath', help='directory path to save file')
	parser.add_argument('-f', '--filePath', dest='filePath', help='file path of currently stored file')
	parser.add_argument('-i', '--fileName', dest='fileName', help='file name')
	parser.add_argument('-n', '--noclobber', dest='noclobber', help='whether or not to overwrite file')
	parser.add_argument('-o', '--output', dest='output', help='output path of log file')
	parser.add_argument('-c', '--contentId', dest='contentId', help='history content id')
	parser.add_argument('-s', '--historyId', dest='historyId', help='history id')
	parser.add_argument('-u', '--outputExt', dest='outputExt', help='output extension of file')
	parser.add_argument('-t', '--toolId', dest='toolId', help='tool id')
	parser.add_argument('-k', '--hostname', dest='hostname', help='iRODS hostname')
	parser.add_argument('-p', '--port', dest='port', help='iRODS port')
	parser.add_argument('-z', '--zone', dest='zone', help='iRODS zone')
	parser.add_argument('-e', '--username', dest='username', help='iRODS username')
	parser.add_argument('-m', '--metadata', dest='metadata', nargs='*', help='metadata name')
	parser.add_argument('-r', '--resource', dest='resource', help='resource name to save to')
	args = parser.parse_args()
	password = os.environ['PASS']
	if args.resource == None:
	       args.resource = "blank"
	newIrodsObject = irods_push_0_0_2.IrodsCredentials(args.hostname, args.port, args.zone, args.username, password, args.output)

	#create new collection, if it doesn't already exist
	newIrodsObject.addDirectories(args.dirPath)

	filePath = [args.filePath]
	fileName = [args.fileName]

	newIrodsObject.addFiles(filePath, fileName, args.dirPath, args.noclobber, args.resource)
	
	#add automatic defined metadata
	if args.metadata != None:
                keys, values = addUserDefinedMetadata(args.metadata)
                newIrodsObject.addMetadataFromList(fileName, args.dirPath, keys,values)
	
	#add auto-generated metadata to a list to be added one by one, in this case we 
	#have to define the key for these values.
	listOfMeta = addAutoDefinedMetadata(filePath, args.toolId, args.contentId, args.historyId, args.outputExt)
	newIrodsObject.addMetadata(fileName, args.dirPath, listOfMeta)

def addAutoDefinedMetadata(filePath, toolId, contentId, historyId, outputExt):
	listOfMeta = []
	listOfMeta.append(toolId)
	listOfMeta.append(contentId)
	listOfMeta.append(historyId)
	listOfMeta.append(outputExt)
	creation_date = time.ctime(os.path.getctime(filePath[0]))
	listOfMeta.append(creation_date)
	listOfMeta.append(str(os.path.getsize(filePath[0])))
	return listOfMeta

#set two lists containing the keys and values
def addUserDefinedMetadata(metadataList):
	keys = []
	
	values = []

	for x in range(0,len(metadataList)-1,2):
		keys.append(metadataList[x])
		values.append(metadataList[x+1])
	return keys, values		

if __name__ == '__main__':
        main()

