from irods.exception import get_exception_by_code, NetworkException
from irods.models import Collection,User,DataObject
from irods.session import iRODSSession

def get_n_dirs(hostname,port,zone,username,password,n):
	sess = iRODSSession(host=str(hostname),port=int(port),zone=str(zone),user=str(username),password=str(password))
	basicPath = "/" + zone + "/home/" + username
	coll = sess.collections.get(basicPath)
	collections = []
		
	myList = get_dirs(coll,n,collections,basicPath)
	myList.append((basicPath,basicPath,0))
	myList = set(myList)
	myList = list(myList)
	sess.cleanup()
	return myList		
	
def get_dirs(coll,n,myColList,basicPath):	
	try:
		n=int(n)
	except:
		n = 0
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
