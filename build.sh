#!/usr/bin/env bash
set -euo pipefail

xla_dir="${HOME}/xla"
zml_dir="${HOME}/zml"
artifact_dir="${HOME}/pjrt-artifacts"
artifact_root="${artifact_dir}/.local/artifact"
libpjrt_oneapi_override="+oneapi_packages+libpjrt_oneapi=${artifact_root}"

cd "$xla_dir"

bazel build --config=sycl_hermetic -c opt //xla/pjrt/c:pjrt_c_api_gpu_plugin.so

mkdir -p "$artifact_dir"
rm -rf "$artifact_root"
mkdir -p "$artifact_root"
cp -f "${xla_dir}/bazel-bin/xla/pjrt/c/pjrt_c_api_gpu_plugin.so" "${artifact_root}/libpjrt_oneapi.so"
cp "${zml_dir}/platforms/oneapi/libpjrt_oneapi.BUILD.bazel" "${artifact_root}/BUILD.bazel"
touch "${artifact_root}/WORKSPACE"
printf 'Using local libpjrt_oneapi override: %s\n' "$artifact_root"

cd "$zml_dir"

bazel build \
  @libpjrt_oneapi//:sandbox \
  --@zml//platforms:cpu=false \
  --@zml//platforms:oneapi=true \
  --override_repository="$libpjrt_oneapi_override"

bazel build \
  //examples/llm \
  --@zml//platforms:cpu=false \
  --@zml//platforms:oneapi=true \
  -c opt \
  --override_repository="$libpjrt_oneapi_override"

ONEAPI_DEVICE_SELECTOR=level_zero:0 \
./bazel-bin/examples/llm/llm \
  --model=/var/models/meta-llama/Llama-3.1-8B-Instruct \
  --topk=1 \
  --prompt="Tell me a story about a brave knight and a dragon in 50 words."

rm -rf "$artifact_root"
