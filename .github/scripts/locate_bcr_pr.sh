#!/usr/bin/env bash

set -euo pipefail

FORK_OWNER="${REGISTRY_FORK%%/*}"
HEAD_REF="${FORK_OWNER}:periphery-${TAG_NAME}"

for attempt in 1 2 3 4 5; do
  RESPONSE=$(curl --silent --show-error --location --get \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --data-urlencode "state=open" \
    --data-urlencode "head=${HEAD_REF}" \
    "https://api.github.com/repos/${REGISTRY}/pulls")

  PR_NUMBER=$(jq --raw-output '.[0].number // empty' <<<"${RESPONSE}")
  if [[ -n "${PR_NUMBER}" ]]; then
    echo "number=${PR_NUMBER}" >> "$GITHUB_OUTPUT"
    exit 0
  fi

  sleep 5
done

echo "Could not find an open pull request for ${HEAD_REF}"
exit 1
