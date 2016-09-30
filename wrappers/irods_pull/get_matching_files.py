import getpass
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject, DataAccess
from irods.session import iRODSSession
		
'''
Find files that match search criteria. First eliminate files based on substring,
then based on key value pairs. If there is not substring, just match on key value
pairs and if there are no key value pairs, match only one substring.
'''
def get_matching_files(hostname,port,zone,username,password,substring,keyvalsList):
	matchFiles = []
	sess = iRODSSession(host=str(hostname),port=str(port),user=str(username),password=str(password),zone=str(zone))
	accessible_files = []
	query = sess.query(Collection.name, DataObject.name).filter(DataAccess.type >= '1050').all()
	for result in query:
		resultString = str(result[Collection.name]) + "/" + str(result[DataObject.name])
		accessible_files.append(resultString)	
		

	matchingFiles = []
	if len(substring) >= 1:
		for item in accessible_files:
			if item.find(str(substring)) != (-1):
				matchFiles.append(item)
	if len(keyvalsList) >= 1:
		if str(keyvalsList[0]["key"]) == '' and str(keyvalsList[0]["value"]) == '':
			keyvalsList = []
	if len(matchFiles) < 1 and len(keyvalsList) < 1:
		sess.cleanup()
		return []
	elif len(keyvalsList) < 1 and len(matchFiles) >= 1:
		sess.cleanup()
		filesToMatch = []
		for item in matchFiles:
			filesToMatch.append((item,item,0))
		return filesToMatch
	elif len(keyvalsList) >= 1 and len(matchFiles) < 1:
		matchFiles = accessible_files
	endFiles = []
	if len(keyvalsList) >= 1:
		for filename in matchFiles:
			
			obj = sess.data_objects.get(filename)	
			flag = True
			foundAFalse = False
			for item in keyvalsList:
				listOfMatching = obj.metadata.get_all(str(item["key"]))
				if len(listOfMatching) < 1:
					flag = False
				else:
					for matchingMeta in listOfMatching:
						value = matchingMeta.value
						if len(str(item["value"])) < 1:
							flag = True
						elif str(value) == str(item["value"]):
							flag = True
						else:
							flag = False
							foundAFalse = True
			if foundAFalse == False:
				endFiles.append(filename)
	matchingFiles = []
	for item in endFiles:
		matchingFiles.append((item,item,0))

	sess.cleanup()
	return matchingFiles
