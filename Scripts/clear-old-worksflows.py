#!/usr/bin/env python3

import argparse
import json
import os
import urllib.parse
import urllib.request
from typing import Any, Generator

API_BASE_URL = "https://api.github.com"
REQUEST_ACCEPT = "application/vnd.github+json"
REQUEST_USER_AGENT = "magnetikonline/remove-workflow-run"

WORKFLOW_RUN_LIST_PAGE_SIZE = 100
WORKFLOW_RUN_LIST_PAGE_MAX = 10


def github_request(
    auth_token: str,
    path: str,
    method: str | None = None,
    parameter_collection: dict[str, str] | None = None,
    parse_response=True,
) -> dict[str, Any]:
    # build base request URL/headers
    request_url = f"{API_BASE_URL}/{path}"
    header_collection = {
        "Accept": REQUEST_ACCEPT,
        "Authorization": f"token {auth_token}",
        "User-Agent": REQUEST_USER_AGENT,
    }

    if method is None:
        # GET method
        if parameter_collection is not None:
            request_url = (
                f"{request_url}?{urllib.parse.urlencode(parameter_collection)}"
            )

        request = urllib.request.Request(headers=header_collection, url=request_url)
    else:
        # POST/PATCH/PUT/DELETE method
        request = urllib.request.Request(
            headers=header_collection, method=method, url=request_url
        )

    response = urllib.request.urlopen(request)
    response_data = {}
    if parse_response:
        response_data = json.load(response)

    response.close()
    return response_data


def workflow_run_list(
    auth_token: str, owner_repo_name: str, workflow_id: str
) -> Generator[str, None, None]:
    request_page = 1
    while request_page <= WORKFLOW_RUN_LIST_PAGE_MAX:
        data = github_request(
            auth_token,
            f"repos/{owner_repo_name}/actions/workflows/{urllib.parse.quote(workflow_id)}/runs",
            parameter_collection={
                "page": str(request_page),
                "per_page": str(WORKFLOW_RUN_LIST_PAGE_SIZE),
            },
        )

        run_list = data["workflow_runs"]
        if len(run_list) < 1:
            # no more items
            break

        for item in run_list:
            yield item["id"]

        # move to next page
        request_page += 1


def workflow_run_delete(auth_token: str, owner_repo_name: str, run_id: str):
    github_request(
        auth_token,
        f"repos/{owner_repo_name}/actions/runs/{run_id}",
        method="DELETE",
        parse_response=False,
    )


def main():
    # fetch GitHub access token
    try:
        auth_token = os.environ["GITHUB_TOKEN"]
    except KeyError:
        print("GITHUB_TOKEN environment variable not set")
    # fetch requested repository and workflow ID to remove prior runs from
    parser = argparse.ArgumentParser()
    parser.add_argument("--repository-name", required=True)
    parser.add_argument("--workflow-id", required=True)
    parser.add_argument("--github-token", required=True)
    arg_list = parser.parse_args()


    # set GitHub access token to auth_token
    auth_token = arg_list.github_token

    while True:
        # fetch run id list chunk from repository workflow
        # note: chunk will be no more than (WORKFLOW_RUN_LIST_PAGE_SIZE * WORKFLOW_RUN_LIST_PAGE_MAX)
        run_id_list = list(
            workflow_run_list(
                auth_token, arg_list.repository_name, arg_list.workflow_id
            )
        )

        if not run_id_list:
            # no further workflow runs
            break

        for run_id in run_id_list:
            print(f"Deleting run ID: {run_id}")
            try:
                workflow_run_delete(auth_token, arg_list.repository_name, run_id)
            except:
                print("fail")


if __name__ == "__main__":
    main()
