#!/bin/bash

set -e

ORG="${ORG:-az-digital}"
TEMPLATE="${TEMPLATE:-template}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"

REPO_NAME="${REPO_NAME:-$1}"
FULL_NAME="${ORG}/${REPO_NAME}"

if [[ -z "${REPO_NAME}" ]]; then
  echo "Please specify the name of the repo"
  exit 1
fi

# Remove direct members
echo "[+] Removing any direct memberships for repo"
for USER in $(gh api "/repos/${ORG}/${REPO_NAME}/collaborators?affiliation=direct" | jq -r '.[] | .login' | tr '\n' ' '); do
  echo "  [+] Removing ${USER}"
  gh api --silent -XDELETE "/repos/${ORG}/${REPO_NAME}/collaborators/${USER}"
done

# Add maintainers
echo "[+] Adding maintainers"
gh api --silent \
  -XPUT "/orgs/${ORG}/teams/maintainers/repos/${ORG}/${REPO_NAME}" \
  --raw-field "permission=maintain"

# Add developers
echo "[+] Adding developers"
gh api --silent \
  -XPUT "/orgs/${ORG}/teams/developers/repos/${ORG}/${REPO_NAME}" \
  --raw-field "permission=push"

# Set branch permissions for default branch
echo "[+] Setting branch permissions for ${DEFAULT_BRANCH}"
jq -n '{"required_status_checks": {"strict": true, "contexts": []}, "enforce_admins": false, "required_pull_request_reviews": {"dismiss_stale_reviews": true, "require_code_owner_reviews": true, "required_approving_review_count": 2}, "required_linear_history": true, "restrictions": {"users":[], "teams": ["maintainers"]}}' | \
gh api --silent \
  -H "Accept: application/vnd.github.luke-cage-preview+json" \
  -XPUT "/repos/${ORG}/${REPO_NAME}/branches/${DEFAULT_BRANCH}/protection" \
  --input -

# Set merge strategy
echo "[+] Setting merge strategy"
jq -n '{"allow_squash_merge": true, "allow_merge_commit": false, "allow_rebase_merge": false, "delete_branch_on_merge": true}' | \
gh api --silent \
  -XPATCH "/repos/${ORG}/${REPO_NAME}" \
  --input -

# Enable vulnerability alerts
echo "[+] Enabling vulnerability alerts"
gh api --silent \
  -H "Accept: application/vnd.github.dorian-preview+json" \
  -XPUT "/repos/${ORG}/${REPO_NAME}/vulnerability-alerts"

# Enable automated security fixes
echo "[+] Enabling automated security fixes"
gh api --silent \
  -H "Accept: application/vnd.github.london-preview+json" \
  -XPUT "/repos/${ORG}/${REPO_NAME}/automated-security-fixes"
