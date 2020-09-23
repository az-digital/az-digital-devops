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
  --confirm \
  --public \
  --template "${ORG}/${TEMPLATE}"

(
  cd "${REPO_NAME}"
  SSH_URL=$(gh api "/repos/${ORG}/${REPO_NAME}" | jq -r '.ssh_url')
  git remote set-url origin "${SSH_URL}"
  git pull origin main
  git branch --set-upstream-to=origin/main main
)

# Apply the defaults
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "${DIR}/defaults.sh"

# Open new repo in browser
gh repo view --web "${FULL_NAME}"
