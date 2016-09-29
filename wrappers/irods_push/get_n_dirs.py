from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession

import getpass
import json
import six
import time
import hashlib
import os

class irodsGetDirectories:
	port = 0
	host =""
	username = ""
	zone =""
	pw = ""
	sess = None

	def __init__(self,host,port,zone,username,password):
		self.host = host
		self.port = port
		self.zone = zone
		self.username = username
		self.password = password
		print host
		print port
		print zone
		print username
		print password
	def basicPath(self):
		return "/" + self.zone + "/home/" + self.username 



def get_n_dirs(hostname,port,zone,username,password,n):
	#newIrods = irodsGetDirectories(host,port,zone,username,password)
	#sess = iRODSSession(host=newIrods.host,port=newIrods.port,user=newIrods.username,password=newIrods.pw,zone=newIrods.zone)
	sess = iRODSSession(host=str(hostname),port=int(port),zone=str(zone),user=str(username),password=str(password))
	print "sess: " + str(sess)
	basicPath = "/" + zone + "/home/" + username
	coll = sess.collections.get(basicPath)
	collections = []
		
	myList = get_dirs(coll,n,collections,basicPath)
	myList.append((basicPath,basicPath,0))
	myList = set(myList)
	myList = list(myList)
	#for i in range(len(myList)):
	#	print type(myList[i])
	#	print myList[i]	

	#print sess.pool.idle
	#print sess.pool.active
	sess.cleanup()
	#print sess.pool.active
	return myList		
	
def get_dirs(coll,n,myColList,basicPath):	
	print "Before cast: " + str(type(n))
	try:
		n=int(n)
	except:
		n = 0
	print "After cast: " + str(type(n))	
	if n == 0:
		return []
	if n == 1:
		myColList.append((basicPath,basicPath,0))
		return myColList
	else:
		for col in coll.subcollections:
			if col is not None:
				myColList.append((col.path,col.path,0))
			
				get_dirs(col,n-1,myColList,basicPath)
		return myColList
