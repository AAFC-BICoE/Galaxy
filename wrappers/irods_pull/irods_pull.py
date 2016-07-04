
import csv
import sys
import getpass
import irods_pull_0_0_1
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"

print "List of files: " + str(sys.argv[1])
#myList = sys.argv[1].split(',')
#for i in range(len(myList)):
#	print "This is an arguement: "  + myList[i] +"\n"

#print len(sys.argv)
print "All arguments: " + str(sys.argv)
listOfFileNames = []
#if str(sys.argv[-1]) == "exi":
#	if len(sys.argv[1]) > 1:
#		listOfFileNames=sys.argv[1].split(',')
#	else:
#		listOfFileNames=sys.argv[1]
#else:
for i in range(1,len(sys.argv)-2):
	listOfFileNames.append(sys.argv[i])
print "List of files: " + str(listOfFileNames)
newIrods = irods_pull_0_0_1.irodsPull(envFile,pwFile,sys.argv[-2],sys.argv[-1])

newIrods.pull_and_push(listOfFileNames)


