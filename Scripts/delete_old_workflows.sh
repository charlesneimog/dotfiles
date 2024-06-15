#!/bin/bash

# GitHub repository information
owner=$1
repo=$2
workflow_id=$3

# Personal access token from command-line argument
token=$4

# Check if the token variable is empty
if [[ -z "$token" ]]; then
  echo "Error: Personal access token is not provided."
  exit 1
fi

# Check if the required command-line arguments are provided
if [[ -z "$owner" || -z "$repo" || -z "$workflow_id" ]]; then
  echo "Error: Insufficient command-line arguments."
  echo "Usage: ./script.sh <owner> <repo> <workflow_id> <token>"
  exit 1
fi

# Get all workflow runs for the repository and specified workflow ID
runs=$(gh api -X GET "/repos/$owner/$repo/actions/workflows/$workflow_id/runs" -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json" | jq -r '.workflow_runs[].id')

# Delete each workflow run
for run_id in $runs; do
  echo "Deleting workflow run ID: $run_id"
  gh api -X DELETE "/repos/$owner/$repo/actions/runs/$run_id" -H "Authorization: token $token" -H "Accept: application/vnd.github.v3+json"
done

