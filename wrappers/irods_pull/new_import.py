import sys
import os
import irods_pull_0_0_1
if not os.path.exists(sys.argv[-1]):
	os.makedirs(sys.argv[-1])

print "sys.argv1: " + sys.argv[1]
print "sys.argv2: " + sys.argv[2]
print "sys.argv3: " + sys.argv[3]
print "sys.argv4: " + sys.argv[4]
print "sys.argv5: " + sys.argv[5]
print "sys.argv6: " + sys.argv[6]


if sys.argv[5] == 'None':
	sys.exit("Please specify file(s) to import")
totalList = []
'''
Take all the file names starting from argument 6 and add to a list to iterate through and
add to the irods filesystem.
'''
x = 5
while x < len(sys.argv)-1:
	print "x:" + str(x)
	print "sys.argv[x]: " + sys.argv[x]
	myList = sys.argv[x].split(",")
	totalList = totalList + myList
	x = x + 1

password =  os.environ['PASS']
print password
newIrods = irods_pull_0_0_1.irodsPull(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4],password)
newIrods.pull_and_push(totalList,sys.argv[-1])
