from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession

import password_obfuscation
import getpass
import json


class irodsGetDirectories:
	port = 0
	host =""
	username = ""
	zone =""
	pw = ""
	sess = None

	def __init__(self):
		pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
		envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"
		with open(pwFile) as f:
			first_line = f.readline().strip()
		self.pw = password_obfuscation.decode(first_line)

		with open(envFile) as f:
			data = json.load(f)
		self.port = str(data["irods_port"])
		self.host = str(data["irods_host"])
		self.zone = str(data["irods_zone_name"])
		self.username = str(data["irods_user_name"])
		self.sess = iRODSSession(host=self.host, port=self.port, user=self.username, password=self.pw, zone=self.zone)

	def basicPath(self):
		return "/" + self.zone + "/home/" + self.username 



def get_n_dirs(n):
	newIrods = irodsGetDirectories()
	sess = newIrods.sess
	basicPath = newIrods.basicPath()
	#print newIrods.zone
	coll = sess.collections.get(basicPath)
	#i = 1
	collections = []
		
	myList = get_dirs(coll,n,collections,basicPath)
	#while i <= n:
	#	for col in coll.subcollections:
	#		collections.append(self.basicPath() + "/" + col.name)
	#	coll = col
	#	i = i+1
	myList = set(myList)
	myList = list(myList)
	for i in range(len(myList)):
		print myList[i]	
	return myList		
	
def get_dirs(coll,n,myColList,basicPath):	
	
		
#	print "N as you enter: " + str(n)	
#	print "Type of myColList as entering: " + str(type(myColList))
	if n == 0:
		myColList.append(basicPath)
		return myColList
	else:
		for col in coll.subcollections:
			#if col.name == 'myDir':
			#	for colIn in col.subcollections:
			#		print colIn.name
#			print "n is: " + str(n)
			#print "Current coll: " + coll.name
			#print "Current col: " + col.name
			#if col is None:
				#print "Current col: " + col.name + " is None"
			#print "Type of col: " + str(type(col))
			if col is not None:
#				print "Type of myColList: " + str(type(myColList))
#				print "Print current List: " + str(myColList)
				myColList.append(col.path)
#				print "Type of myColList after: " + str(type(myColList))
					
				get_dirs(col,n-1,myColList,basicPath)
		return myColList
		#print col

#newIrods = irodsGetDirectories()
get_n_dirs(2)	
