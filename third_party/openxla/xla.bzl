load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

OPENXLA_COMMIT = "9f7da682d8c1e4a4eae772104f4cfae3ae789b72"
OPENXLA_SHA256 = "07a480bddfd6cd8021e7919dd218070c8e0ee3b7833378ee71415e2485fe512a"

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
