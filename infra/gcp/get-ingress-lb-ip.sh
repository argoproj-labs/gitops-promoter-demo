#!/usr/bin/env bash
# Print the ingress-nginx Service external IPv4 address for DNS A records.
# Requires: kubectl configured for the target cluster, ingress-nginx installed.
set -euo pipefail

svc="ingress-nginx-controller"
ns="ingress-nginx"

ip="$(kubectl get svc -n "${ns}" "${svc}" \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

if [[ -z "${ip}" ]]; then
  echo "No external IP yet for ${ns}/${svc} (LoadBalancer still provisioning, or Service missing)." >&2
  echo "Check: kubectl get svc -n ${ns}" >&2
  exit 1
fi

echo "${ip}"
