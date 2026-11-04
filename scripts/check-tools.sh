#!/usr/bin/env bash
# Phase 0 checklist: are the tools installed, and are you logged in to each cloud?
# Usage: ./scripts/check-tools.sh
set -uo pipefail

ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
bad()  { printf '  \033[31m✘\033[0m %s\n' "$*"; FAILED=1; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
FAILED=0

echo "Tools"
for tool in git terraform aws az gcloud docker jq; do
  if command -v "$tool" >/dev/null 2>&1; then
    case "$tool" in
      terraform) v=$(terraform version | head -1) ;;
      aws)       v=$(aws --version 2>&1) ;;
      az)        v="azure-cli $(az version --query '"azure-cli"' -o tsv 2>/dev/null)" ;;
      gcloud)    v=$(gcloud version 2>/dev/null | head -1) ;;
      *)         v=$("$tool" --version 2>&1 | head -1) ;;
    esac
    ok "$tool — $v"
  else
    bad "$tool is not installed"
  fi
done

for tool in tflint checkov; do
  command -v "$tool" >/dev/null 2>&1 && ok "$tool (optional)" || warn "$tool not installed (optional, used from project 09 on)"
done

echo
echo "Cloud logins"
if command -v aws >/dev/null 2>&1; then
  if id=$(aws sts get-caller-identity --query Arn --output text 2>/dev/null); then
    ok "AWS: $id"
    [[ "$id" == *":root" ]] && warn "You're using the AWS ROOT user — create an IAM Identity Center user instead"
  else
    bad "AWS: not logged in (run: aws configure sso && aws sso login)"
  fi
fi

if command -v az >/dev/null 2>&1; then
  if sub=$(az account show --query '[name, id]' -o tsv 2>/dev/null | paste -sd' '); then
    ok "Azure: subscription $sub"
    [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]] && warn "Set ARM_SUBSCRIPTION_ID for Terraform: export ARM_SUBSCRIPTION_ID=\$(az account show --query id -o tsv)"
  else
    bad "Azure: not logged in (run: az login)"
  fi
fi

if command -v gcloud >/dev/null 2>&1; then
  acct=$(gcloud config get-value account 2>/dev/null)
  proj=$(gcloud config get-value project 2>/dev/null)
  if [[ -n "$acct" ]]; then
    ok "GCP: $acct (project: ${proj:-none set})"
    [[ -z "$proj" ]] && warn "Set a default project: gcloud config set project <PROJECT_ID>"
    gcloud auth application-default print-access-token >/dev/null 2>&1 \
      && ok "GCP: application-default credentials present (used by Terraform)" \
      || bad "GCP: no application-default credentials (run: gcloud auth application-default login)"
  else
    bad "GCP: not logged in (run: gcloud auth login)"
  fi
fi

echo
if [[ $FAILED -eq 0 ]]; then
  echo "All set — go to foundations/README.md, exercise 1."
else
  echo "Fix the ✘ items above, then run this again."
fi
exit $FAILED
