'''
This class uses the python-irodsclient api. Make sure it is installed on your computer. This class also uses the 
password_obfuscation.py file which can be found on the irods github main page. It requires you to have the 
module 'six' installed.
'''
import sys
import os
import exceptions
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession
import password_obfuscation 
#import getpass
import json

class FileDuplicateError(Exception):
	pass

class HierarchyError(Exception):
	pass


#TODO add a file as an attribute of the class and have the file get filled as functions are called, then at the end get that attribute and make it as the galaxy output
#TODO figure out a way to make class attributes in python private.
class irodsCredentials:
	port = 0
	host = ""
	username = ""
	zone = ""
	pw = ""
	sess = None
	outFile = None	
	#initialize your irods session by reading off irods credentials from .irodsA file and from irods_environment.json file
	def __init__(self,envFilePath,pwFilePath,outFile):
		with open(pwFilePath) as f:
			first_line = f.readline().strip()
		#decode scrambled password from .irodsA file using decode function
		self.pw = password_obfuscation.decode(first_line)
		with open(envFilePath) as f:
			data = json.load(f)
		self.port = str(data["irods_port"])
		self.host = str(data["irods_host"])
		self.zone = str(data["irods_zone_name"])
		self.username = str(data["irods_user_name"])
		self.sess = iRODSSession(host=self.host, port=self.port, user=self.username, password=self.pw, zone=self.zone)	
		self.outFile = outFile
	#Established so no user should be able to put something in anything higher than their main root directory. 
	def basicPath(self):
		return "/" + self.zone + "/home/" + self.username + "/"

	#TODO add a check for the main root directories, making sure an error is thrown if the program is passed any of the following directories: zone, home, or username directory.
	#check if collection exists, if it does, return True, otherwise False
	def checkIfCollectionExists(self,dirName):
		if dirName[0] == '/':
			dirName = dirName[1:]
		query = self.sess.query(Collection).filter(Collection.name == self.basicPath() + dirName)
		results = query.all()
		if len(results) <= 0:
			with open(self.outFile,"a+") as f:
        	                f.write("Collection '" + dirName + "' doesn't exist\n")
			return False
		with open(self.outFile,"a+") as f:
			print dirName
                        f.write("Collection '" + dirName + "' exists\n")
		return True
	#Split up the string of directories delimited by '/' and create collections within collections until there are no more directories.	
	def addDirectories(self,dirName):
		if dirName[0] == '/':
			dirName = dirName[1:]
		if self.checkIfCollectionExists(dirName) == False:
			strList = dirName.split('/',1)
			f = open(self.outFile,"a+")
			currentPath = ""
			for t in range(len(strList)):
				#only bother creating a new collection within the collection if it doesn't already exist	
				if self.checkIfCollectionExists(currentPath + strList[t]) == False:
					f.write("Created collection: " + self.basicPath() + currentPath + strList[t] + "\n")
					obj = self.sess.collections.create(self.basicPath() + currentPath + strList[t])
				#this is to make sure you are not just creating the collections in your root directory.
				currentPath = currentPath + strList[t] + "/"

	#Add files to iRODS. If the file already exists, check if noclobber = true, if it is true then overwrite the existing file in memory. If the 
	#file does not already exist, go ahead and create it.
	def addFiles(self,filePaths,fileNames,dirName,noclobber):
		if dirName[0] == '/':
			dirName = dirName[1:]
		if len(fileNames) != len(set(fileNames)):
                                raise FileDuplicateError("Error: You are trying to add a file two or more times, try again with two different names")
                myOutFile = open(self.outFile,"a+")
		for x in range(len(filePaths)):
			if not os.path.exists(filePaths[x]):
				raise IOError("Error: File path specified does not exist")	
			#check if file exists before deciding whether or not to just create it or overwrite it.		
			query = self.sess.query(DataObject).filter(DataObject.name == fileNames[x]).filter(Collection.name == self.basicPath() + dirName)
			results = query.all()
			
			#file doesn't exist so create it, don't need to check for 'no clobber'
			if len(results) <= 0:
				myOutFile.write("File '" + fileNames[x] + "' does not exist. Creating it in irods.\n")
				#print dirName
				#print self.basicPath() + dirName + "/" + fileNames[x]
				obj = self.sess.data_objects.create(self.basicPath() + dirName + "/" + fileNames[x])
				with open(filePaths[x]) as fileToPlace:
					data = fileToPlace.read()
				#print self.basicPath() + dirName + "/" + fileNames[x]
				obj = self.sess.data_objects.get(self.basicPath() + dirName + "/" + fileNames[x])
				with obj.open('w+') as f:
					f.write(data)			
					f.seek(0,0)
		
				obj = self.sess.data_objects.get(self.basicPath() + dirName + "/" + fileNames[x])
				myOutFile.write("Succesfully wrote: " + fileNames[x] + "\n")
			#at this point it is assumed the file already exists
			else: 
				if noclobber == "true":
					myOutFile.write("File '" + fileNames[x] + "' already exists. Overwriting now.\n")
					obj = self.sess.data_objects.get(self.basicPath() + dirName + "/" + fileNames[x])
					data = ""
					with obj.open('w+') as f:
						f.write(data)
			
					with open(filePaths[x]) as fileToPlace:
						data = fileToPlace.read()
					obj = self.sess.data_objects.get(self.basicPath() + dirName + "/" + fileNames[x])
					with obj.open('w+') as f:
						f.write(data)
						f.seek(0,0)
					obj = self.sess.data_objects.get(self.basicPath() + dirName + "/" + fileNames[x])
					myOutFile.write("Successfully overwrote: " + fileNames[x] + "\n")
				else:
					myOutFile.write("File '" + fileNames[x] + "' already exists. Prevented from overwriting\n")
				

#newIrods = irodsCredentials("/home/katherine/.irods/irods_environment.json", "/home/katherine/.irods/.irodsA")
#newIrods.addDirectories("katDir/newDir/files")
#filePaths = []
#fileNames = []
#filePaths.append("/home/katherine/filler.txt")
#filePaths.append("/home/katherine/joy.txt")
#fileNames.append("filler.txt")
#fileNames.append("joy.txt")
#newIrods.addFiles(filePaths,fileNames,"katDir/newDir/files","true")



