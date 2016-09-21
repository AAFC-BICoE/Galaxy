import sys
import os
import irods_pull_0_0_1
if not os.path.exists(sys.argv[-1]):
	os.makedirs(sys.argv[-1])

totalList = []
x = 6
while x < len(sys.argv)-1:
	print "x:" + str(x)
	print "sys.argv[x]: " + sys.argv[x]
	myList = sys.argv[x].split(",")
#	totalList.extend(myList)
	totalList = totalList + myList
	x = x + 1
#myList = sys.argv[-2].split(",")

#this takes the string of filenames and makes it into a list of filenames
#for x in range(len(myList)):
#	myList[x] = myList[x].rsplit('/',1)[-1]


#for name in myList:
#	with open(os.path.join(sys.argv[-1],name),'w') as out:
#		out.write("Hello world")
newIrods = irods_pull_0_0_1.irodsPull(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],sys.argv[5])
newIrods.pull_and_push(totalList,sys.argv[-1])
