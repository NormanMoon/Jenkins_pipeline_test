#!/bin/bash
set -x


# Project ID
project_id="10007"

issuetype_id="10000"

summary="Parent"

description="Parent"


##################################################################################################################


token=$1

template='{

  "fields": {
    "summary": "%s",
    "project": {
      "id": "%s"
    },
    "issuetype": {
      "id": "%s"
    },
    "description": "%s"

    }
}'

json_final=$(printf "$template" \
                    "$summary" \
                    "$project_id" \
                    "$issuetype_id" \
                    "$description")

curl -v -i -X POST \
          -u norman.moon@aboutobjects.com:"$token" \
          -H "Content-Type:application/json" \
          -H "Accept: application/json" \
          -H "X-Atlassian-Token:no-check" \
          "https://normanmoon.atlassian.net/rest/api/2/issue/" \
          -d \
          "$json_final" \
          -o create-parent-ticket-test.out