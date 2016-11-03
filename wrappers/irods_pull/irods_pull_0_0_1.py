from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession
import exceptions
import sys
import os
import string
class irodsPull:
	port = 0
	host= ""
	username = ""
	zone = ""
	pw = ""
	sess = None

	def __init__(self,hostname,port,zone,username,password):
		print "hostname: " + hostname
		print "port: " + port
		print "zone: " + zone
		print "username: " + username
		print "password: " + password
		self.host = hostname
		try:
			float(port)
		except ValueError:
			sys.exit("Make sure the port is a number")
		self.port= port
		self.zone = zone
		self.username = username
		self.pw = password
		try:
		
			self.sess = iRODSSession(host=self.host, port=self.port, user=self.username, password=self.pw, zone=self.zone)
			coll = self.sess.collections.get("/" + self.zone + "/home/" + self.username)
		except NetworkException:
			sys.exit("Invalid user credentials")
	def checkIfFileExists(self,filePath):
		try:
			obj=self.sess.data_objects.get(filePath)
			return True
		except:
			sys.exit("One of the files you selected either does not exist or you do not have read access.")
	#Given a list of filepaths, make sure their file paths are kosher with the irods api 'get' call, give it the
	#appropriate output file path so that galaxy will recognize multiple output files are being created. 		
	def pull_and_push(self,filePaths,collectionName):
		for filePath in filePaths:
		#	print filePath
			try:
				answer = self.sess.data_objects.get(filePath)
			except:
				print "The file you are trying to open does not exist or you do not have permission to open it." 
				sys.exit(" ")
			try:
				with answer.open('r') as f:
					data = f.read()
			except:	
				print "The file: " + filePath + " either does not exist or you do not have read access permissions."
				sys.exit(" ")
        		filePath = filePath.rsplit('/',1)[-1]
			with open(os.path.join(collectionName,filePath),"a+") as fout:
				fout.write(data)
		#	with open(os.path.join(collectionName,filePath),"r") as fread:
		#		print fread.read()
		self.sess.cleanup()


