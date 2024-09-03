load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

OPENXLA_COMMIT = "336122e2fb0e3d7dd93b5a4a30f7551d8e1a21b6"
OPENXLA_SHA256 = "9ea232552b417dac4a16481692291e82f012b81876393f52712b695b57869ac4"

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
