#!/usr/bin/env bash

set -euo pipefail

REPO_NAME="${1:-secure-aws-landing-zone}"

VISIBILITY="${2:-public}" # public keeps Actions free + portfolio-visible

cd "$(dirname "$0")"

if ! gh auth status > /dev/null 2>&1; then
	echo "Not logged into GitHub. Run: gh auth login"
	exit 1
fi

# Create repo + push (skips if remote already set)

if ! git remote get-url origin > /dev/null 2>&1; then
	gh create repo "$REPO_NAME" --"$VISIBILITY" --source=. --push \
		--description "Multi-account AWS landing zone in Terraform: SCP guardrails, SSO, OIDC CI/CD, full audit logging."
	git branch -M main
else
	git push -ou origin main
fi

OWNER="$(gh repo view --json owner -q '.owner.login')"
gh api --method POST "/repos/${OWNER}/${REPO_NAME}/rulesets" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2026-03-10" --input - <<< '
{
	"name": "Protect Main Branch",
	"target": "branch",
	"enforcement": "active",
	"conditions": {
		"ref_name": {

			"include": ["refs/heads/main"],
			"exclude": []
		}
	},
	"rules": [
		{
			"type": "pull_request",
			"parameters": {
				"required_approving_review_count": 0,
				"dismiss_stale_reviews_on_push": true,
				"require_code_owner_review": false,
				"require_last_push_approval": false,
				"required_review_thread_resolution": false
			}
		}
	]
}'
