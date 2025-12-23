# AGENT PLAYBOOK

This repository builds PJRT artifacts for the OpenXLA project.  
When CI breaks because upstream changes invalidate our pinned commit or patches, follow this checklist to repair it.

## 1. Workspace basics
- Use SSH for GitHub access (`git@github.com:zml/pjrt-artifacts.git`).
- Workflow lives in `.github/workflows/_build.yaml`; default commit pins must always track a revision verified locally.
- Custom patches live under `openxla/patches/{upstream,rocm}` and are applied before every build.

## 2. Checking and Fixing nightly builds
Nightly runs are defined in `.github/workflows/nightly.yaml`. Always read that file first—its matrix specifies the authoritative OpenXLA (`XLA_COMMIT`) and ROCm (`ROCM_XLA_COMMIT`) SHAs that nightly builds expect. When fixing nightly failures, validate both repos at those exact SHAs unless the task explicitly asks to move them forward.
1. Confirm the listed SHAs build:
   - Clone `openxla/xla` at `XLA_COMMIT` and apply `openxla/patches/upstream/*.patch`.
   - Clone `ROCm/xla` at `ROCM_XLA_COMMIT` and apply `openxla/patches/rocm/*.patch` when debugging ROCm nightly failures.
2. Only update the commit values in `_build.yaml`/`nightly.yaml` after verifying both the upstream checkout and `bazel` commands succeed.

## 3. Updating to a new OpenXLA commit
1. **Clone upstream via SSH**
   ```bash
   git clone git@github.com:openxla/xla.git openxla-work
   cd openxla-work
   git checkout <target commit or main>
   ```
2. **Apply upstream patches**
   ```bash
   git apply ../openxla/patches/upstream/*.patch
   ```
   - If any patch fails, edit it inside `openxla/patches/upstream/…` so that it applies cleanly to the new commit (e.g., update context or add missing loads).  
   - Keep patches minimal; they must stay in sync with the repo copy committed later.
3. **Run a quick Bazel validation**
   ```bash
   bazel --batch --output_base="$(pwd)/.bazel_output" query //xla/pjrt/c:pjrt_c_api_cpu_plugin
   ```
   - `--output_base` inside the repo keeps permissions simple.
   - If Bazel refuses to start (port permissions or missing deps), adjust the patches or add Bazelrc overrides locally until the query succeeds.
4. **Record extra tweaks**
   - When a patch adds new Bazel macros (e.g., `http_archive`), ensure the patch itself contains any required loads so future checkouts do not need manual edits.

## 4. Updating pjrt-artifacts
1. **Edit `.github/workflows/_build.yaml`**
   - Set `XLA_COMMIT` (and ROCm if needed) to the validated SHA.
   - Update the inline comment with the actual commit date (grab via `git show -s --format=%ci <sha>`).
2. **Update patches**
   - Copy any edits from the temporary checkout back into the corresponding patch files under `openxla/patches/...`.
   - Keep diffs ASCII and deterministic; number patches sequentially.
3. **Document testing**
   - Always re-run the Bazel query after editing patches to confirm they still apply.
   - If build steps are required (cuda/rocm), mention the configs in the PR body even if not run locally.

## 5. Commit & PR etiquette
1. Stage relevant files only (workflow + updated patches).
2. Commit with attribution, e.g., `Fix OpenXLA commit date comment (by ChatGPT)`.
3. Push the branch (`git push origin HEAD`) and create a PR using `gh pr create --base master --head <branch>`.
4. PR body template:
   ```
   ## Summary
   - describe workflow/patch changes

   ## Testing
   - bazel --batch --output_base="$(pwd)/.bazel_output" query //xla/pjrt/c:pjrt_c_api_cpu_plugin
   ```

## 6. Troubleshooting notes
- **Bazel output permissions:** If `/var/tmp` is read-only, override `--output_base`.
- **Missing symbols in patches:** Make sure required `load()` statements are added; otherwise Bazel commands will fail with “name 'http_archive' is not defined.”
- **SSH requirement:** The environment often rewrites HTTPS URLs to SSH, so always prefer `git@github.com:` URIs to avoid cloning failures.

Keep this file current whenever the workflow changes. Future agents should be able to follow these steps end-to-end without extra context.
