#!/usr/bin/env bash
# Patch a Kubernetes secret key with a Sentry release git SHA.
# Assumes kubectl is already authenticated to the target cluster/namespace.
# Does not print secret payloads or tokens.
set -euo pipefail

SECRET_NAME="${SECRET_NAME:-}"
RELEASE_SHA="${RELEASE_SHA:-}"
SECRET_KEY="${SECRET_KEY:-RELEASE_GIT_SHA}"
NAMESPACE="${NAMESPACE:-}"

if [[ -z "${SECRET_NAME}" ]]; then
  echo "error: SECRET_NAME is required" >&2
  exit 1
fi

if [[ -z "${RELEASE_SHA}" ]]; then
  echo "error: RELEASE_SHA is required" >&2
  exit 1
fi

if [[ -z "${SECRET_KEY}" ]]; then
  echo "error: SECRET_KEY is required" >&2
  exit 1
fi

if [[ -z "${NAMESPACE}" ]]; then
  NAMESPACE="$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null || true)"
fi

if [[ -z "${NAMESPACE}" ]]; then
  echo "error: NAMESPACE is required (pass explicitly or configure kubectl context namespace)" >&2
  exit 1
fi

# Build merge patch without embedding values in process listings via echo -n pipes.
# stringData accepts plaintext; the API server base64-encodes into .data.
PATCH_FILE="$(mktemp)"
trap 'rm -f "${PATCH_FILE}"' EXIT

# Use jq so secret key/sha are JSON-escaped (never logged).
jq -n \
  --arg key "${SECRET_KEY}" \
  --arg sha "${RELEASE_SHA}" \
  '{stringData: {($key): $sha}}' >"${PATCH_FILE}"

echo "Updating Sentry release key '${SECRET_KEY}' on secret '${SECRET_NAME}' in namespace '${NAMESPACE}'"

kubectl patch secret "${SECRET_NAME}" \
  --namespace "${NAMESPACE}" \
  --type merge \
  --patch-file "${PATCH_FILE}"
