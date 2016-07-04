from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession
import password_obfuscation
import json
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
	outfileid = ""
	newFilePath = ""
	outfile = ""

	def __init__(self,envFilePath,pwFilePath,outfileid,newFilePath):
		with open(pwFilePath) as f:
			first_line = f.readline().strip()

		self.pw = password_obfuscation.decode(first_line)
		with open(envFilePath) as f:
			data = json.load(f)
		self.port = str(data["irods_port"])
		self.host = str(data["irods_host"])
		self.zone = str(data["irods_zone_name"])
		self.username = str(data["irods_user_name"])
		self.sess = iRODSSession(host=self.host, port=self.port, user=self.username, password=self.pw, zone=self.zone)
		#this is just the filename
		self.outfileid = str(outfileid)
		self.newFilePath = str(newFilePath)
		
	def checkIfFileExists(self,filePath):
		try:
			obj=self.sess.data_objects.get(filePath)
			return True
		except:
			sys.exit("One of the files you selected either does not exist or you do not have read access.")
			
	def pull_and_push(self,filePaths):

		for filePath in filePaths:	
			if filePath[0] != '/':
				filePath = '/' + filePath
			if filePath[-1] == '/':
				filePath = filePath[0:len(filePath)-1]
			pathList = filePath.split('/')
			firstPath, file_ext = os.path.splitext(filePath)
			filePathForGalaxy = string.replace(pathList[-1],"_","-")			
			filename = "primary_" + self.outfileid +"_" + filePathForGalaxy + "_visible_" + str(file_ext[1:])
			#may need to insert escape characters for spaces.
			exists = self.checkIfFileExists(filePath)
			answer = self.sess.data_objects.get(filePath)
			#print str(answer)
			#print filePath
			#print str(answer)
			try:
				with answer.open('r') as f:
					data = f.read()
			except:	
				sys.exit("You do not have permission to access this file.")

			with open(filename,"a+") as fout:
				fout.write(data)
				#f.seek(0,0)
		self.sess.cleanup()
#		return self.outFile


