#!/usr/bin/env bash

set -euo pipefail

COMMENTS=$(curl --silent --show-error --location \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/${REGISTRY}/issues/${PR_NUMBER}/comments")

if jq -e --arg body "${COMMENT_BODY}" '.[] | select(.body == $body)' <<<"${COMMENTS}" >/dev/null; then
  echo "Comment already exists on PR #${PR_NUMBER}"
  exit 0
fi

PAYLOAD=$(jq --null-input --arg body "${COMMENT_BODY}" '{body: $body}')

curl --silent --show-error --location \
  --request POST \
  --header "Accept: application/vnd.github+json" \
  --header "Authorization: Bearer ${GITHUB_TOKEN}" \
  --header "X-GitHub-Api-Version: 2022-11-28" \
  --data "${PAYLOAD}" \
  "https://api.github.com/repos/${REGISTRY}/issues/${PR_NUMBER}/comments" >/dev/null
