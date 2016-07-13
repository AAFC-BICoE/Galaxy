
import sys
import getpass
import irods_pull_0_0_1
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"

listOfFileNames = []
if str(sys.argv[-1]) == "exi":
	listOfFileNames=sys.argv[1].split(',')
else:
	for i in range(1,len(sys.argv)-3):
		listOfFileNames.append(sys.argv[i])

newIrods = irods_pull_0_0_1.irodsPull(envFile,pwFile,sys.argv[-3],sys.argv[-2])

newIrods.pull_and_push(listOfFileNames)


