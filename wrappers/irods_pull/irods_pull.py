

import sys
import getpass
import irods_pull_0_0_1
pwFile = "/home/" + getpass.getuser() + "/.irods/.irodsA"
envFile = "/home/" + getpass.getuser() + "/.irods/irods_environment.json"


newIrods = irods_pull_0_0_1.irodsPull(envFile,pwFile,sys.argv[-1])

newIrods.pull_and_push(sys.argv[1])


