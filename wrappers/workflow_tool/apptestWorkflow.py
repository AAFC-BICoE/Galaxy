import sys
import os
from bioblend import galaxy
from bioblend.galaxy.client import Client

url = sys.argv[1]
api_key = sys.argv[2]
gi = galaxy.GalaxyInstance(url=url, key=api_key)
wfclient = galaxy.workflows.WorkflowClient(gi)
workflow_id = sys.argv[3]
dictJSON = wfclient.export_workflow_json(workflow_id)
invocations = wfclient.get_invocations(workflow_id)
#print "dictJson: " + str(dictJSON)
#collectionName = sys.argv[4]
#invocation_id = "c385e49b9fe1853c"
#invocation_details = wfclient.show_invocation(workflow_id,invocation_id) 
#invocation_step_id = "b887d74393f85b6d"
#invocation_step = wfclient.show_invocation_step(workflow_id,invocation_id,invocation_step_id)
#dictJSON = wfclient.get_workflows()
#print url
#print api_key
#print str(gi)
#print workflow_id
listInvocations = []
for element in invocations:
	
	listInvocations.append(element['id'])
lastInvocation = str(listInvocations[-1])
invocation_details = wfclient.show_invocation(workflow_id,lastInvocation)

jobids = []
for job_dict in invocation_details['steps']:
	jobids.append(job_dict['job_id'])
jobClient = galaxy.jobs.JobsClient(gi)
params = []
for job_id in jobids:
	details = jobClient.show_job(job_id,full_details=True)
	params.append(details["params"])
#print "params: " + str(params)
#workflow file
wfclient.export_workflow_to_local_path(workflow_id,sys.argv[4],use_default_filename=False)
#with open(sys.argv[4],"a+") as fout:
#	fout.write("Hello world")
#input file
with open(sys.argv[5], "a+") as fout2:
	fout2.write(str(params))

#filePathGA = lastInvocation + ".txt"
#filePathInputs = lastInvocation + ".txt"
#print "collectionName: " + collectionName
#wfclient.export_workflow_to_local_path(workflow_id, os.path.join(collectionName, filepathGA),use_default_filename=False)
#with open(collectionName,"r") as fout:
#	print fout.read()
#print "invocation details" + str(invocation_details)
#print "invocation step " + str(invocation_step)




