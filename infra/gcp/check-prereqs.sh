#!/usr/bin/env bash
set -euo pipefail

echo "== Tooling =="
if command -v gcloud >/dev/null 2>&1; then
  echo "gcloud: OK ($(command -v gcloud))"
  gcloud --version | head -n 1
else
  echo "gcloud: NOT FOUND"
fi

if command -v terraform >/dev/null 2>&1; then
  echo "terraform: OK ($(command -v terraform))"
  terraform version | head -n 1
else
  echo "terraform: NOT FOUND"
fi

echo
echo "== gcloud auth =="
if command -v gcloud >/dev/null 2>&1; then
  account="$(gcloud config get-value account 2>/dev/null || true)"
  if [[ -z "$account" || "$account" == "(unset)" ]]; then
    echo "No active gcloud account. Run: gcloud auth login"
  else
    echo "Active account: $account"
  fi
else
  echo "Skipping auth check because gcloud is unavailable."
fi

echo
echo "== gcloud ADC =="
adc_path="${HOME}/.config/gcloud/application_default_credentials.json"
if [[ -f "$adc_path" ]]; then
  echo "ADC file present: $adc_path"
else
  echo "ADC missing. Run: gcloud auth application-default login"
fi

echo
echo "== billing accounts =="
if command -v gcloud >/dev/null 2>&1; then
  if ! gcloud billing accounts list --format="table(name,displayName,open)"; then
    echo "Unable to list billing accounts until authenticated."
  fi
else
  echo "Skipping billing check because gcloud is unavailable."
fi

