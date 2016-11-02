'''
This class uses the python-irodsclient api. Make sure it is installed on your computer. This class also uses the 
'''
import sys
import os
import exceptions
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession

class FileDuplicateError(Exception):
	pass

class HierarchyError(Exception):
	pass

'''
Class to hold irods credentials and create irods session.
'''
class IrodsCredentials:
	port = 0
	host = ""
	username = ""
	zone = ""
	pw = ""
	sess = None
	outFile = None	
	#Make sure there are no errors with the credentials at this point.
	def __init__(self,hostname,port,zone,username,password,outFile):
		self.host = str(hostname)
		try:
			float(port)
		except ValueError:
			sys.exit("Make sure the port is a number")
		self.port = str(port)
		self.zone = str(zone)
		self.username = str(username)
		self.pw = str(password)		
		try:
			
			self.sess = iRODSSession(host=self.host, port=self.port, user=self.username, password=self.pw, zone=self.zone)	
			#this is just to assure valid credentials were passed.
			col = self.sess.collections.get("/" + self.zone + "/home/" + self.username)
		except NetworkException:
			sys.exit("Invalid user credentials")
		self.outFile = outFile

	#check if collection exists, if it does, return True, otherwise False
	def checkIfCollectionExists(self,dirName):
		if dirName[0] != '/':
			dirName = '/' + dirName
		if dirName[-1] == '/':
			dirName = dirName[0:len(dirName)-1]
		if dirName == "/" + self.zone or dirName == "/" + self.zone + "/home" or dirName == "/" +self.zone + "/home/" + self.username:
			return True
		query = self.sess.query(Collection).filter(Collection.name == dirName)
		results = query.all()
		if len(results) <= 0:
			with open(self.outFile,"a+") as f:
        	                f.write("Collection '" + dirName + "' doesn't exist\n")
			return False
		with open(self.outFile,"a+") as f:
                        f.write("Collection '" + dirName + "' exists\n")
		return True

	#Split up the string of directories delimited by '/' and create collections within collections until there are no more directories.	
	def addDirectories(self,dirName):
		if dirName[0] != '/':
                        dirName = '/' + dirName
                if dirName[-1] == '/':
                        dirName = dirName[0:len(dirName)-1]
		if self.checkIfCollectionExists(dirName) == False:
			strList = dirName.split('/')
			if strList[0] == "":
				del strList[0]
			f = open(self.outFile,"a+")
			currentPath = "/"
			for t in range(len(strList)):
				if self.checkIfCollectionExists(currentPath + strList[t]) == False:
					f.write("Created collection: " + currentPath + strList[t] + "\n")
					try:	
						obj = self.sess.collections.create(currentPath + strList[t])
					except:
						sys.exit( "Can't create this directory, it already exists, or you do not have permission to write to the current directory. If using an absolute path, make sure your path looks something like this if you are a user: '/<yourzone>/home/<yourusername>/... ")
						
				#this is to make sure you are not just creating the collections in your root directory.
				currentPath = currentPath + strList[t] + "/"

	#Add files to iRODS. If the file already exists, check if noclobber = true, if it is true then overwrite the existing file in memory. If the 
	#file does not already exist, go ahead and create it.
	def addFiles(self,filePaths,fileNames,dirName,noclobber,resourceName):
		#make path kosher with what irods wants.
		if dirName[0] != '/':
                        dirName = '/' + dirName
                if dirName[-1] == '/':
                        dirName = dirName[0:len(dirName)-1]
		if len(fileNames) != len(set(fileNames)):
                                raise FileDuplicateError("Error: You are trying to add a file two or more times, try again with two different names")
                myOutFile = open(self.outFile,"a+")
		for x in range(len(filePaths)):
			fileNames[x] = fileNames[x].replace('/',' ')
			if not os.path.exists(filePaths[x]):
				raise IOError("Error: File path specified does not exist")	
			#check if file exists before deciding whether or not to just create it or overwrite it.		
			query = self.sess.query(DataObject).filter(DataObject.name == fileNames[x]).filter(Collection.name == dirName)
			results = query.all()
			
			#file doesn't exist so create it, don't need to check for 'no clobber'
			if len(results) <= 0:
				myOutFile.write("File '" + fileNames[x] + "' does not exist. Creating it in irods.\n")
				if resourceName != "blank":
					try:
						obj = self.sess.data_objects.create(dirName + "/" + fileNames[x], resourceName)
					except:
						sys.exit("You do not have permission to write to this directory path")
				else:
					try:
						obj = self.sess.data_objects.create(dirName + "/" + fileNames[x])
					except: 		
						sys.exit("You do not have permission to write to this directory path")
		
				with open(filePaths[x]) as fileToPlace:
					data = fileToPlace.read()
				obj = self.sess.data_objects.get(dirName + "/" + fileNames[x])
				with obj.open('w+') as f:
					f.write(data)			
					f.seek(0,0)
		
				obj = self.sess.data_objects.get(dirName + "/" + fileNames[x])
				myOutFile.write("Succesfully wrote: " + fileNames[x] + "\n")
			#at this point it is assumed the file already exists
			else: 
				if noclobber == "true":
					myOutFile.write("File '" + fileNames[x] + "' already exists. Overwriting now.\n")
					obj = self.sess.data_objects.get(dirName + "/" + fileNames[x])
					data = ""
					with obj.open('w+') as f:
						f.write(data)
			
					with open(filePaths[x]) as fileToPlace:
						data = fileToPlace.read()
					obj = self.sess.data_objects.get(dirName + "/" + fileNames[x])
					with obj.open('w+') as f:
						f.write(data)
						f.seek(0,0)
					obj = self.sess.data_objects.get(dirName + "/" + fileNames[x])
					myOutFile.write("Successfully overwrote: " + fileNames[x] + "\n")
				else:
					myOutFile.write("File '" + fileNames[x] + "' already exists. Prevented from overwriting\n")

	def addMetadata(self,fileName,dirName,metadata):
		obj = self.sess.data_objects.get(dirName + "/" + fileName[0])	
		listOfMeta = obj.metadata.get_all('tool_id') 
		if listOfMeta > 0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('tool_id',metadata[0])
		listOfMeta = obj.metadata.get_all('history_content_id')
		if listOfMeta > 0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('history_content_id',metadata[1])	
		listOfMeta = obj.metadata.get_all('history_id')
		if listOfMeta > 0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('history_id',metadata[2])
		listOfMeta = obj.metadata.get_all('format')
		if listOfMeta >0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('format',metadata[3])
		listOfMeta = obj.metadata.get_all('creation_time')
		if listOfMeta > 0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('creation_time',metadata[4])
		listOfMeta = obj.metadata.get_all('size')
		if listOfMeta > 0:
			for i in listOfMeta:
				obj.metadata.remove(i)
		obj.metadata.add('size',metadata[5])	

	#add metadata to file from lists of user generated metadata.
	def addMetadataFromList(self,fileName,dirName,keys,values):
		if len(keys) < 0 and len(values) < 0:
			self.sess.cleanup()
			return
		obj = self.sess.data_objects.get(dirName + "/" + fileName[0])
		lenOfMeta = len(keys)
		for x in range(lenOfMeta):
			listOfMeta = obj.metadata.get_all(keys[x])
			if listOfMeta > 0:
				for i in listOfMeta:
					obj.metadata.remove(i)
			obj.metadata.add(keys[x],values[x])
		self.sess.cleanup()
	




