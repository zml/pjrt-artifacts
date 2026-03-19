#!/usr/bin/env bash

set -euo pipefail

xla_branch="main"
rocm_xla_branch="rocm-jaxlib-v0.9.1"

xla_commit="$(
  gh api "repos/openxla/xla/commits/${xla_branch}" --jq '.sha'
)"
rocm_xla_commit="$(
  gh api "repos/ROCm/xla/commits/${rocm_xla_branch}" --jq '.sha'
)"

cat <<EOF
XLA_BRANCH=${xla_branch}
XLA_COMMIT=${xla_commit}
ROCM_XLA_BRANCH=${rocm_xla_branch}
ROCM_XLA_COMMIT=${rocm_xla_commit}
EOF
