import sys
import os
import irods_pull_0_0_1
import argparse

def main():
	parser = argparse.ArgumentParser(description="Process import tool parameters")
	parser.add_argument('-o', '--hostname', dest='hostname', help='iRODS hostname')
	parser.add_argument('-p', '--port', dest='port', help='iRODS port')
	parser.add_argument('-z', '--zone', dest='zone', help='iRODS zone')
	parser.add_argument('-u', '--username', dest='username', help='iRODS username')
	parser.add_argument('-a', '--pathName', dest='pathName', nargs='*', help='File path names')
	parser.add_argument('-c', '--collectionName', dest='collectionName', help='Name of collection as it appears in Galaxy history')
	password = os.environ['PASS']
	args = parser.parse_args()
	if not os.path.exists(args.collectionName):
		os.makedirs(args.collectionName)
	if args.pathName == 'None':
		sys.exit('Please specify file(s) to import')
	totalList = []
	print "args.pathName: " + str(args.pathName)
	for item in args.pathName:
		myList = item.split(",")
		totalList = totalList + myList
	print totalList
	newIrods = irods_pull_0_0_1.irodsPull(args.hostname,args.port,args.zone,args.username,password)
	newIrods.pull_and_push(totalList,args.collectionName)
	
if __name__ == '__main__':
	main()

#if not os.path.exists(sys.argv[-1]):
#	os.makedirs(sys.argv[-1])

#print "sys.argv1: " + sys.argv[1]
#print "sys.argv2: " + sys.argv[2]
#print "sys.argv3: " + sys.argv[3]
#print "sys.argv4: " + sys.argv[4]
#print "sys.argv5: " + sys.argv[5]
#print "sys.argv6: " + sys.argv[6]


#if sys.argv[5] == 'None':
#	sys.exit("Please specify file(s) to import")
#totalList = []
'''
Take all the file names starting from argument 5 and add to a list to iterate through and
add to the irods filesystem.
'''
#x = 5
#while x < len(sys.argv)-1:
#	print "x:" + str(x)
#	print "sys.argv[x]: " + sys.argv[x]
#	myList = sys.argv[x].split(",")
#	totalList = totalList + myList
#	x = x + 1
#
#password =  os.environ['PASS']
#print password
#newIrods = irods_pull_0_0_1.irodsPull(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],password)
#newIrods.pull_and_push(totalList,sys.argv[-1])
