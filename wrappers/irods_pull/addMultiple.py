import sys
import os
#print str(sys.argv)
for i in range(1,len(sys.argv)-2):
	print sys.argv[i]
	filenamer, file_ext = os.path.splitext(str(sys.argv[i]))
	filename = "primary_" + str(sys.argv[-2]) + "_" + str(sys.argv[i]) + "_visible_"+ str(file_ext[1:]) 
	print "This is the complete filename:" + filename
	with open(filename,"a+") as f:
		f.write("Hello jane\n")
		if i==1:
			print "I got here and i is: " + str(i)
			print "Current file is: " + sys.argv[i]
			f.write("We meet again")

