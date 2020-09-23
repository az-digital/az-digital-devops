#!/bin/bash

set -e

ORG="az-digital"
TEMPLATE="template"
DEFAULT_BRANCH="main"

REPO_NAME="${1}"
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

# Add maintainers
gh api --silent -XPUT "/orgs/${ORG}/teams/maintainers/repos/${ORG}/${REPO_NAME}" \
  --raw-field "permission=maintain"

# Add developers
gh api --silent -XPUT "/orgs/${ORG}/teams/developers/repos/${ORG}/${REPO_NAME}" \
  --raw-field "permission=push"

# Set branch permissions for default branch
jq -n '{"required_status_checks": {"strict": true, "contexts": []}, "enforce_admins": true, "required_pull_request_reviews": {"dismiss_stale_reviews": true, "require_code_owner_reviews": true, "required_approving_review_count": 2}, "required_linear_history": true, "restrictions": {"users":[], "teams": []}}' | \
gh api --silent -H "Accept: application/vnd.github.luke-cage-preview+json" -XPUT "/repos/${ORG}/${REPO_NAME}/branches/${DEFAULT_BRANCH}/protection" --input -

# Open new repo in browser
gh repo view --web "${FULL_NAME}"
