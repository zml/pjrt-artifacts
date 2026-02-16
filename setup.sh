#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOW_FILE="$ROOT_DIR/.github/workflows/_build.yaml"
PATCH_ROOT="$ROOT_DIR/openxla/patches"
BUILD_DIR="$ROOT_DIR/build"
YQ_MODE=""

FORK="upstream"
REF=""
CLONE_DIR=""

usage() {
  cat <<'USAGE'
Usage: setup.sh [--fork upstream|rocm] [--ref <git-ref-or-sha>] [--dir <clone-dir>]

Clones the requested OpenXLA fork, checks out the pinned commit (or --ref),
applies patches, and prints build commands from the workflow matrix.
USAGE
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

detect_yq_mode() {
  if yq e -r '.env.XLA_COMMIT' "$WORKFLOW_FILE" >/dev/null 2>&1; then
    YQ_MODE="mikefarah"
    return
  fi
  if yq -r '.env.XLA_COMMIT' "$WORKFLOW_FILE" >/dev/null 2>&1; then
    YQ_MODE="python"
    return
  fi
  echo "Unable to determine yq flavor. Install mikefarah/yq or python yq with jq support." >&2
  exit 1
}

yq_read() {
  local expr="$1"
  case "$YQ_MODE" in
    mikefarah)
      yq e -r "$expr" "$WORKFLOW_FILE"
      ;;
    python)
      yq -r "$expr" "$WORKFLOW_FILE"
      ;;
    *)
      echo "Internal error: yq mode not initialized" >&2
      exit 1
      ;;
  esac
}

extract_sha() {
  local raw="$1"
  local sha
  sha=$(echo "$raw" | sed -E "s/.*'([0-9a-f]{40})'.*/\1/")
  if [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    echo "$sha"
  else
    echo "$raw"
  fi
}

get_env_commit() {
  local key="$1"
  local raw
  raw=$(yq_read ".env.${key}")
  if [[ -z "$raw" || "$raw" == "null" ]]; then
    echo "";
    return
  fi
  extract_sha "$raw"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fork)
      FORK="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      shift 2
      ;;
    --dir)
      CLONE_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac

done

require_cmd yq

if [[ ! -f "$WORKFLOW_FILE" ]]; then
  echo "Workflow file not found: $WORKFLOW_FILE" >&2
  exit 1
fi

detect_yq_mode

case "$FORK" in
  upstream)
    REPO="git@github.com:openxla/xla.git"
    PATCH_DIR="upstream"
    DEFAULT_REF=$(get_env_commit "XLA_COMMIT")
    ;;
  rocm)
    REPO="git@github.com:ROCm/xla.git"
    PATCH_DIR="rocm"
    DEFAULT_REF=$(get_env_commit "ROCM_XLA_COMMIT")
    ;;
  *)
    echo "Invalid --fork value: $FORK (expected upstream|rocm)" >&2
    exit 2
    ;;
 esac

if [[ -z "$CLONE_DIR" ]]; then
  CLONE_DIR="$BUILD_DIR/$FORK"
fi

CHECKOUT_REF="${REF:-$DEFAULT_REF}"
if [[ -z "$CHECKOUT_REF" ]]; then
  echo "Unable to determine checkout ref." >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"
if [[ -d "$CLONE_DIR/.git" ]]; then
  echo "Using existing repo at $CLONE_DIR"
  git -C "$CLONE_DIR" fetch --all --tags
else
  echo "Cloning $REPO into $CLONE_DIR"
  git clone "$REPO" "$CLONE_DIR"
fi

echo "Checking out $CHECKOUT_REF"
git -C "$CLONE_DIR" checkout "$CHECKOUT_REF"

if [[ ! -d "$PATCH_ROOT/$PATCH_DIR" ]]; then
  echo "Patch directory not found: $PATCH_ROOT/$PATCH_DIR" >&2
  exit 1
fi

echo "Applying patches from $PATCH_ROOT/$PATCH_DIR"
for patch in $(ls "$PATCH_ROOT/$PATCH_DIR"/*.patch | sort); do
  echo "Applying patch $patch"
  git -C "$CLONE_DIR" apply "$patch"
done

rocm_install=$(yq_read '.jobs["pjrt-artifacts"].steps[] | select(.name == "Download ROCm toolchain (not fully hermetic)") | .run')
if [[ "$rocm_install" == "null" ]]; then
  rocm_install=""
fi

echo ""
echo "=== Build commands (from $WORKFLOW_FILE) ==="

matrix_entries=$(yq_read '.jobs["pjrt-artifacts"].strategy.matrix.pjrt[] | [.target,.platform,.bazel_opts,.config,.bazel_target] | @tsv')

while IFS=$'\t' read -r target platform bazel_opts config bazel_target; do
  if [[ -z "$target" ]]; then
    continue
  fi
  if [[ "$FORK" == "rocm" && "$target" != "rocm" ]]; then
    continue
  fi
  if [[ "$FORK" == "upstream" && "$target" == "rocm" ]]; then
    continue
  fi
  if [[ "$bazel_opts" == "null" ]]; then
    bazel_opts=""
  fi
  if [[ "$config" == "null" ]]; then
    config=""
  fi
  if [[ "$bazel_target" == "null" ]]; then
    bazel_target=""
  fi

  if [[ "$target" == "rocm" && -n "$rocm_install" ]]; then
    echo ""
    echo "# ROCm toolchain install (from workflow)"
    printf '%s\n' "$rocm_install"
  fi

  echo ""
  if [[ "$target" == "rocm" ]]; then
    echo "# Target: $target | Platform: $platform | Fork: rocm"
  else
    echo "# Target: $target | Platform: $platform | Fork: upstream"
  fi
  echo "cp \"$ROOT_DIR/openxla/bazelrc/${target}.bazelrc\" \"$CLONE_DIR/xla_configure.bazelrc\""
  if [[ -n "$bazel_opts" ]]; then
    echo "cd \"$CLONE_DIR\" && bazel $bazel_opts build $config $bazel_target"
  else
    echo "cd \"$CLONE_DIR\" && bazel build $config $bazel_target"
  fi

done <<< "$matrix_entries"
