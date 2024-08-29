load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

OPENXLA_COMMIT = "83d4db83e4e7d6dd2200fc2e7acf18e361e8c5a0"
OPENXLA_SHA256 = "969dad5fdb76b0282255255ebe9d3708e30bd033fdbddb4b4de0d7ce42ace56b"

def _xla_impl(mctx):
    http_file(
        name = "openxla",
        sha256 = OPENXLA_SHA256,
        url = "https://github.com/openxla/xla/archive/{}.tar.gz".format(OPENXLA_COMMIT[:7]),
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
