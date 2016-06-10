import sys
#import site
from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection, User, DataObject
from irods.session import iRODSSession
import password_obfuscation
import getpass
import json

with open("/home/" + getpass.getuser() + "/.irods/.irodsA", 'r') as f:
	first_line = f.readline().strip()
answer = password_obfuscation.decode(first_line)
print answer
with open("/home/" + getpass.getuser() + "/.irods/irods_environment.json",'r') as f:
        data = json.load(f)

port = str(data["irods_port"])
print type(port)
host = str(data["irods_host"])
print type(host)
zone = str(data["irods_zone_name"])
print type(zone)
username = str(data["irods_user_name"])
print type(username)

#sess = iRODSSession(host="katherine-VirtualBox",port=1247,user="alice",password="testpassword",zone="tempZone")
sess = iRODSSession(host=host, port=port,user=username,password=answer,zone=zone)
#basicPath = "/tempZone/home/alice/"
basicPath = "/" + zone + "/home/" + username + "/"

query = sess.query(Collection).filter(Collection.name == basicPath + sys.argv[1])
results = query.all()
if len(results) <= 0:
	print "Collection doesn't exist"
	#insert code to keep creating collections as specified by the user.
	path = sys.argv[1]
	strList = path.split('/', 1 )
	if len(strList) > 1:
		currentPath = basicPath
		for t in range(len(strList)):
			print currentPath + strList[t]
			obj = sess.collections.create(currentPath + strList[t])
			currentPath = currentPath + strList[t] + "/"
	else:
		obj = sess.collections.create(basicPath + sys.argv[1])
else:
	print "Collection exists"


pathname = basicPath + sys.argv[1] 
#if the user tries to add two files with the same name, tool should throw an error.
if len(sys.argv) != len(set(sys.argv)):
	raise FileExistsError("Error: Can not add duplicate files, pick one.")

for x in range(2,len(sys.argv)-2,2):
	#check whether or not the file being added already exists in irods.
	query = sess.query(DataObject).filter(DataObject.name == sys.argv[x+1]).filter(Collection.name == pathname)
	results = query.all()
	#file doesn't exist, so create it
	if len(results) <= 0:
		obj = sess.data_objects.create(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
                with open(sys.argv[x]) as fileToPlace:
                        data = fileToPlace.read()
		
                obj = sess.data_objects.get(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
		#put information in new data object in irods 
                with obj.open('w') as f:
                        f.write(data)
                        f.seek(0,0)
		#refresh data object
                obj = sess.data_objects.get(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
                print "Sucessfully wrote: " + sys.argv[x+1]
	#object exists so check if overwrite is checked or not. Only make a change to the file if overwrite is checked.
	else:
		if sys.argv[-1] == "true":
			#get the existing object and empty it out.
			obj = sess.data_objects.get(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
			data = ""
			#empty the content of the file and replace with incoming file contents.
			with obj.open('w') as f:
				f.write(data)
			#take file content of incoming file and put in now empty irods file
			with open(sys.argv[x]) as fileToPlace:
				data = fileToPlace.read()
			obj = sess.data_objects.get(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
			with obj.open('w') as f:
				f.write(data)
				f.seek(0,0)
			#refresh data object
			obj = sess.data_objects.get(basicPath + sys.argv[1] + "/" + sys.argv[x+1])
			print "Successfully overwrote: " + sys.argv[x+1]
			
			
			

