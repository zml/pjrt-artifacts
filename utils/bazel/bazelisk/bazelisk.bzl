load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _bazelisk_impl(mctx):
    http_file(
        name = "bazelisk",
        sha256 = "d9af1fa808c0529753c3befda75123236a711d971d3485a390507122148773a3",
        url = "https://github.com/bazelbuild/bazelisk/releases/download/v1.20.0/bazelisk-linux-amd64",
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
