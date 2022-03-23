#!/bin/bash

set -e

ORG="${ORG:-az-digital}"
TEMPLATE="${TEMPLATE:-template}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

REPO_NAME="${REPO_NAME:-$1}"
FULL_NAME="${ORG}/${REPO_NAME}"

if [[ -z "${REPO_NAME}" ]]; then
  echo "Please specify the name of the new repo"
  exit 1
fi

gh repo create "${FULL_NAME}" \
  --public \
  --template "${ORG}/${TEMPLATE}"

# Apply the defaults
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/defaults.sh"

# Open new repo in browser
gh repo view --web "${FULL_NAME}"
