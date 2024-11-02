OWNER=charlesneimog
REPO=pd4web
WORKFLOW_ID=Wheels.yml

# list workflows
gh api -X GET /repos/$OWNER/$REPO/actions/workflows | jq '.workflows[] | .name,.id'

# copy the ID of the workflow you want to clear and set it

# list runs
gh api -X GET /repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs --paginate | jq '.workflow_runs[] | .id'

# delete runs
gh api -X GET /repos/$OWNER/$REPO/actions/workflows/$WORKFLOW_ID/runs --paginate | jq '.workflow_runs[] | .id' | xargs -I{} gh api -X DELETE /repos/$OWNER/$REPO/actions/runs/{} --silent
