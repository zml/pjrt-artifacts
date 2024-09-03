load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

OPENXLA_COMMIT = "653ae7c566aff19450b34d62980093880d3ad2f1"
OPENXLA_SHA256 = "3da3e1156bd7543809a5061413e4328b8863ac1bb6becc1158b2bfb04d497d4c"

def _xla_impl(mctx):
    http_file(
        name = "openxla",
        sha256 = OPENXLA_SHA256,
        # use this repository until PR is merged: https://github.com/openxla/xla/pull/16696
        url = "https://github.com/zml/xla/archive/{}.tar.gz".format(OPENXLA_COMMIT[:7]),
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
