#!/usr/bin/env bash
# Re-seal all GitLab PAT-backed SealedSecrets in this repo (same token in three places).
# Requires: kubectl (context → cluster with Sealed Secrets), kubeseal matching the controller.
#
# Usage:
#   ./scripts/reseal-gitlab-token.sh
#   (prompts once for the GitLab token; input is hidden)
#
# Optional env (non-secret overrides):
#   GUESTBOOK_GITLAB_REPO_URL  default: https://gitlab.com/gitops-promoter-group/gitops-promoter-project.git
#   GITLAB_HTTPS_USERNAME       default: oauth2 (Argo CD repo-write Secret)

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

for cmd in kubectl kubeseal; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "error: required command not found: $cmd" >&2
    exit 1
  fi
done

unset GITLAB_TOKEN
read -r -s -p "Paste GitLab project access token (hidden): " GITLAB_TOKEN
echo || true

if [[ -z "$GITLAB_TOKEN" ]]; then
  echo "error: empty token" >&2
  exit 1
fi

GITLAB_REPO_URL="${GUESTBOOK_GITLAB_REPO_URL:-https://gitlab.com/gitops-promoter-group/gitops-promoter-project.git}"
GITLAB_HTTPS_USERNAME="${GITLAB_HTTPS_USERNAME:-oauth2}"

kubeseal_gitlab() {
  kubeseal \
    --controller-name sealed-secrets \
    --controller-namespace kube-system \
    "$@"
}

echo "→ gitlab-scm-credentials (namespace gitops-promoter)"
kubectl create secret generic gitlab-scm-credentials -n gitops-promoter \
  --from-literal=token="$GITLAB_TOKEN" \
  --dry-run=client -o yaml \
  | kubeseal_gitlab -o yaml -n gitops-promoter \
    -w charts/gitops-promoter/templates/gitlab-scm-credentials.sealed.yaml

echo "→ argocd-repo-gitlab-guestbook-write (namespace argocd)"
kubectl create secret generic argocd-repo-gitlab-guestbook-write -n argocd \
  --from-literal=type=git \
  --from-literal=url="$GITLAB_REPO_URL" \
  --from-literal=username="$GITLAB_HTTPS_USERNAME" \
  --from-literal=password="$GITLAB_TOKEN" \
  --dry-run=client -o yaml \
  | kubectl label --local --dry-run=client -f - argocd.argoproj.io/secret-type=repository-write -o yaml \
  | kubectl label --local --dry-run=client -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal_gitlab -o yaml -n argocd \
    -w charts/argocd/templates/argocd-repo-gitlab-guestbook-write.sealed.yaml

echo "→ gitlab-demo-churn-credentials (namespace argocd)"
kubectl create secret generic gitlab-demo-churn-credentials -n argocd \
  --from-literal=token="$GITLAB_TOKEN" \
  --dry-run=client -o yaml \
  | kubectl label --local --dry-run=client -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal_gitlab -o yaml -n argocd \
    -w charts/argocd/templates/gitlab-demo-churn-credentials.sealed.yaml

echo
echo "Updated:"
echo "  charts/gitops-promoter/templates/gitlab-scm-credentials.sealed.yaml"
echo "  charts/argocd/templates/argocd-repo-gitlab-guestbook-write.sealed.yaml"
echo "  charts/argocd/templates/gitlab-demo-churn-credentials.sealed.yaml"
echo
echo "Commit and push; Argo CD will apply the new SealedSecrets. Use a Maintainer project token (api + write_repository) so pushes to protected main succeed — see docs/gitlab-demo-setup.md §2."

unset GITLAB_TOKEN
