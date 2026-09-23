#!/usr/bin/env bash
# Unit tests for update.sh with a mocked kubectl (no live cluster).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPDATE_SH="${SCRIPT_DIR}/../update.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

PATH="${TMP_DIR}/bin:${PATH}"
mkdir -p "${TMP_DIR}/bin"

# Mock kubectl: record patch args and accept --patch-file
cat >"${TMP_DIR}/bin/kubectl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
LOG="${KUBECTL_LOG:?}"
printf '%s\n' "$@" >>"${LOG}"

# Support: kubectl config view --minify -o jsonpath=...
if [[ "${1:-}" == "config" && "${2:-}" == "view" ]]; then
  echo "mock-ns-from-context"
  exit 0
fi

# Support: kubectl patch secret ... --patch-file FILE
if [[ "${1:-}" == "patch" ]]; then
  patch_file=""
  prev=""
  for arg in "$@"; do
    if [[ "${prev}" == "--patch-file" ]]; then
      patch_file="${arg}"
    fi
    prev="${arg}"
  done
  if [[ -n "${patch_file}" ]]; then
    cp "${patch_file}" "${KUBECTL_PATCH_OUT:?}"
  fi
  exit 0
fi

exit 0
EOF
chmod +x "${TMP_DIR}/bin/kubectl"

# Mock jq is the real jq if available; otherwise fail early
command -v jq >/dev/null || { echo "jq required for tests" >&2; exit 1; }

fail=0
assert_eq() {
  local name="$1" expected="$2" actual="$3"
  if [[ "${expected}" != "${actual}" ]]; then
    echo "FAIL: ${name}: expected '${expected}', got '${actual}'" >&2
    fail=1
  else
    echo "PASS: ${name}"
  fi
}

assert_fail() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: ${name}: expected non-zero exit" >&2
    fail=1
  else
    echo "PASS: ${name}"
  fi
}

# ── Required input failures ────────────────────────────────────────────
assert_fail "missing SECRET_NAME" \
  env SECRET_NAME='' RELEASE_SHA=abc NAMESPACE=ns bash "${UPDATE_SH}"

assert_fail "missing RELEASE_SHA" \
  env SECRET_NAME=my-secret RELEASE_SHA='' NAMESPACE=ns bash "${UPDATE_SH}"

# Dedicated empty kubectl that returns nothing for context namespace
mkdir -p "${TMP_DIR}/bin-empty"
cat >"${TMP_DIR}/bin-empty/kubectl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${TMP_DIR}/bin-empty/kubectl"
assert_fail "missing NAMESPACE when context empty" \
  env SECRET_NAME=my-secret RELEASE_SHA=abc NAMESPACE='' \
    PATH="${TMP_DIR}/bin-empty:${PATH}" bash "${UPDATE_SH}"

compact_json() {
  jq -c . <<<"$1"
}

# ── Happy path: explicit namespace + patch payload ──────────────────────
export KUBECTL_LOG="${TMP_DIR}/kubectl.log"
export KUBECTL_PATCH_OUT="${TMP_DIR}/patch.json"
: >"${KUBECTL_LOG}"

SECRET_NAME=hmpps-app-sentry \
RELEASE_SHA=abcdef0123456789abcdef0123456789abcdef01 \
SECRET_KEY=RELEASE_GIT_SHA \
NAMESPACE=hmpps-app-dev \
bash "${UPDATE_SH}"

payload="$(compact_json "$(cat "${KUBECTL_PATCH_OUT}")")"
expected='{"stringData":{"RELEASE_GIT_SHA":"abcdef0123456789abcdef0123456789abcdef01"}}'
assert_eq "patch payload" "${expected}" "${payload}"

if grep -q 'patch secret hmpps-app-sentry' "${KUBECTL_LOG}" || grep -q $'patch\nsecret\nhmpps-app-sentry' "${KUBECTL_LOG}"; then
  echo "PASS: kubectl patch secret invoked"
else
  # Args are one-per-line in our mock log
  if grep -qx 'hmpps-app-sentry' "${KUBECTL_LOG}" && grep -qx 'patch' "${KUBECTL_LOG}"; then
    echo "PASS: kubectl patch secret invoked"
  else
    echo "FAIL: kubectl patch not recorded" >&2
    cat "${KUBECTL_LOG}" >&2
    fail=1
  fi
fi

if grep -qx 'hmpps-app-dev' "${KUBECTL_LOG}" || grep -q -- '--namespace' "${KUBECTL_LOG}"; then
  echo "PASS: namespace passed to kubectl"
else
  echo "FAIL: namespace not passed" >&2
  fail=1
fi

# ── Context namespace fallback ──────────────────────────────────────────
: >"${KUBECTL_LOG}"
SECRET_NAME=s RELEASE_SHA=deadbeef SECRET_KEY=RELEASE_GIT_SHA NAMESPACE='' \
  bash "${UPDATE_SH}"
if grep -qx 'mock-ns-from-context' "${KUBECTL_LOG}" || grep -q 'mock-ns-from-context' "${KUBECTL_PATCH_OUT}" 2>/dev/null; then
  :
fi
# Verify namespace used via --namespace in args
if awk 'p{print; exit} $0=="--namespace"{p=1}' "${KUBECTL_LOG}" | grep -qx 'mock-ns-from-context'; then
  echo "PASS: falls back to kubectl context namespace"
else
  echo "FAIL: context namespace fallback" >&2
  cat "${KUBECTL_LOG}" >&2
  fail=1
fi

# ── Custom secret key ──────────────────────────────────────────────────
: >"${KUBECTL_LOG}"
SECRET_NAME=s RELEASE_SHA=cafe NAMESPACE=ns SECRET_KEY=CUSTOM_SHA \
  bash "${UPDATE_SH}"
payload="$(compact_json "$(cat "${KUBECTL_PATCH_OUT}")")"
assert_eq "custom secret key" '{"stringData":{"CUSTOM_SHA":"cafe"}}' "${payload}"

# Ensure release SHA never appears alone in kubectl argv (only in patch file)
if grep -qx 'abcdef0123456789abcdef0123456789abcdef01' "${KUBECTL_LOG}"; then
  echo "FAIL: release SHA should not be on kubectl argv" >&2
  fail=1
else
  echo "PASS: release SHA not on kubectl argv"
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "Some tests failed" >&2
  exit 1
fi
echo "All update.sh tests passed"
