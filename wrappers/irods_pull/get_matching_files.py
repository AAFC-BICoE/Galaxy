import getpass
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject, DataAccess
from irods.session import iRODSSession
		

def get_matching_files(hostname,port,zone,username,password,substring,keyvalsList):
	matchFiles = []
	hostname = "katherine-VirtualBox"
	port="1247"
	zone="tempZone"
	username="rods"
	password="testpassword"
	sess = iRODSSession(host=str(hostname),port=str(port),user=str(username),password=str(password),zone=str(zone))
	accessible_files = []
	query = sess.query(Collection.name, DataObject.name).filter(DataAccess.type >= '1050').all()
	for result in query:
		resultString = str(result[Collection.name]) + "/" + str(result[DataObject.name])
		accessible_files.append(resultString)	
		

	matchingFiles = []
#	print "substring: " + substring
	print "sub len: " + str(len(substring))
	if len(substring) >= 1:
		for item in accessible_files:
			if item.find(str(substring)) != (-1):
				matchingFiles.append(item)
				matchFiles.append((item,item,0))
		print "in substring check: " + str(matchFiles)	
	#keyvalsList is a list of dictionaries, with indices 'key' and 'value'
	if len(keyvalsList) >= 1:
#		print keyvalsList
		if str(keyvalsList[0]["key"]) == '' and str(keyvalsList[0]["value"]) == '':
			keyvalsList = []
	print "keyval list now: " + str(keyvalsList)
	print "len key: " + str(len(keyvalsList))
	print "len match: " + str(len(matchFiles))
	if len(matchFiles) < 1 and len(keyvalsList) < 1:
		print "both empty"
		sess.cleanup()
		return []
	elif len(keyvalsList) < 1 and len(matchFiles) >= 1:
		print "match filled, key empty"
		sess.cleanup()
		return matchFiles
	elif len(keyvalsList) >= 1 and len(matchFiles) < 1:
		matchFiles = accessible_files
	
	
	sess.cleanup()
	return matchFiles
	'''
	flag = True
	finalMatching = []
	if matchFiles is not []:
		print "matchFiles: " + str(matchFiles)
	
	for item in matchingFiles:
		obj = sess.data_objects.get(item)
		if keyvalsList is not []:
			if keyvalsList[0]["key"] is not '' and keysvalsList[0]["value"] is not '' :
				print "keyvalsList: " + str(keyvalsList)	
				for item in keyvalsList:
					flag = True
					if (type(item) is dict) and (bool(item)):
						print item["key"]
						print item["value"]
						#this means it has meta with that key, not necessarily the right value
						exists = obj.metadata.get_all(str(item["key"]))
						if exists is  []:
							flag = False
				if flag == True:
					finalMatching.append((item,item,0))
		else:
			sess.cleanup()
			return matchFiles


#						if flag:
#							if str(item["value"]) == "":
#								flag = True 
							#else if the value doesn't match, flag = False
				#if flag is false at this point, don't add the file to the list	
	'''				
#	outputList = []
#	outputList.append((str(substring),str(substring),0))
#	for i in keyvalsList:
#		
#		outputList.append((str(i["key"]),str(i["key"]),0))
#		
#		outputList.append((str(i["value"]),str(i["value"]),0))
#	outputList.append((str(hostname),str(hostname),0))
#	outputList.append((str(port),str(port),0))
#	outputList.append((str(username),str(username),0))
#	outputList.append((str(password),str(password),0))
#	return outputList
#result = get_matching_files("katherine-VirtualBox","1247","tempZone","rods","testpassword","rods","some")
#print str(result)
'''
def get_matching_files(substring):
        outputList = []
        outputList.append((substring,substring,0))
        #for i in keyvalsList:
        #        if i["key"]:    
         #               outputList.append((i["key"],i["key"],0))
          #      elif i["value"]:
           #             outputList.append((i["value"],i["value"],0))
        return outputList
'''
