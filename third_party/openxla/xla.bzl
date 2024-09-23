load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

# While https://github.com/openxla/xla/pull/16696 isn't merge
# we use fork of xla with the patch applied.
# This version was chosen because it contains the gather/scatter broadcasting dims.
# https://github.com/zml/xla/tree/gw/2024_09_19
# Reference commit on xla@main: https://github.com/zml/xla/commit/d391119197eab771a84c1f8a59a7f50b7da4b43d
OPENXLA_COMMIT = "177464c630b8acd2ba9795f81c0248bdaedfb3cf"
OPENXLA_SHA256 = "48b33e15c4479c8c7421cfc5fa0c02f82af73e706c0ce7b383539cdeb55e3a41"

def _xla_impl(mctx):
    http_file(
        name = "openxla",
        sha256 = OPENXLA_SHA256,
        # use this repository until PR is merged: https://github.com/openxla/xla/pull/16696
        url = "https://github.com/zml/xla/archive/{}.tar.gz".format(OPENXLA_COMMIT),
        # url = "https://github.com/openxla/xla/archive/{}.tar.gz".format(OPENXLA_COMMIT[:7]),
        downloaded_file_path = "openxla_github.tar.gz",
    )

    return mctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
    )

xla = module_extension(
    implementation = _xla_impl,
)
