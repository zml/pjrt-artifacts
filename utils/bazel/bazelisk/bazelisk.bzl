load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _bazelisk_impl(mctx):
    http_file(
        name = "bazelisk",
        sha256 = "fd8fdff418a1758887520fa42da7e6ae39aefc788cf5e7f7bb8db6934d279fc4",
        url = "https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64",
        downloaded_file_path = "usr/bin/bazelisk",
        executable = True,
    )
    return mctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
    )

bazelisk = module_extension(
    implementation = _bazelisk_impl,
)
