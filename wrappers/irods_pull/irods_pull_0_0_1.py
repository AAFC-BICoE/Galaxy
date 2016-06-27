
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession
import password_obfuscation
import json
import exceptions


class irodsPull:
	port = 0
	host= ""
	username = ""
	zone = ""
	pw = ""
	sess = None
	outFile = None

	def __init__(self,envFilePath,pwFilePath,outfile):
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
		self.outFile = outfile

	def checkIfFileExists(self,filePath):
		try:
			obj=sess.data_objects.get(filePath)
			return True
		except:
			sys.exit("You either do not have permission to access this file or the file does not exist")
			
	def pull_and_push(self,filePath):
		answer = self.sess.data_objects.get(filePath)
		with answer.open('r+') as f:
			data = f.read()

		with open(self.outFile,"w") as fout:
			fout.write(data)
			#f.seek(0,0)
		return self.outFile



				






