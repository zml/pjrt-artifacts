#!/usr/bin/env bash

set -euo pipefail

xla_branch="main"
rocm_xla_branch="rocm-jaxlib-v0.9.0"
oneapi_xla_branch="zml/oneapi"

xla_commit="$(
  gh api "repos/openxla/xla/commits/${xla_branch}" --jq '.sha'
)"
rocm_xla_commit="$(
  gh api "repos/ROCm/xla/commits/${rocm_xla_branch}" --jq '.sha'
)"
oneapi_xla_commit="$(
  gh api "repos/zml/xla/commits/${oneapi_xla_branch}" --jq '.sha'
)"

cat <<EOF
XLA_BRANCH=${xla_branch}
XLA_COMMIT=${xla_commit}
ROCM_XLA_BRANCH=${rocm_xla_branch}
ROCM_XLA_COMMIT=${rocm_xla_commit}
ONEAPI_XLA_BRANCH=${oneapi_xla_branch}
ONEAPI_XLA_COMMIT=${oneapi_xla_commit}
EOF
