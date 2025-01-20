load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file" ,"http_archive")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

OPENXLA_COMMIT = "b91b6f1ad0e75b2295f811a262cdce744180d2ea"
OPENXLA_SHA256 = "6db47dd23cacc281cc591374915d66bd7b1a4749fc5ec6e53cd180f9039f7829"

def _xla_impl(mctx):
    http_archive(
        name = "openxla",
        sha256 = OPENXLA_SHA256,
        url = "https://github.com/openxla/xla/archive/{}.tar.gz".format(OPENXLA_COMMIT),
        strip_prefix = "xla-{}".format(OPENXLA_COMMIT),
        add_prefix = "openxla",
        build_file_content = """
filegroup(
    name = "all_files",
    srcs = subpackages(include = ["**"]),
    visibility = ["//visibility:public"],
)
        """,
        patch_args = [
            "-d",
            "openxla",
            "-p1",
        ],
        patches = [
            "patches/20240131-001-Expose-PJRT-mlir_to_hlo-to-public.patch",        
            "patches/20240318-001-PJRT-C-API-Ensure-C-compliance-for-Profiler-Extension.patch",
            "patches/20240901-001-Do-not-force-DEVELOPER_DIR-on-macOS.patch", # PR: https://github.com/openxla/xla/pull/16696
            "patches/20240901-002-Set-the-macosx-deployment-target-via-the-bazel-command-line.patch", # PR: https://github.com/openxla/xla/pull/16696
            "patches/20240901-003-Only-export-GetPjrtApi-symbol-on-macOS.patch", # PR: https://github.com/openxla/xla/pull/16696
            "patches/20250120-001-Enable-nvptxcompiler-with-nvjitlink.patch", # Allow us to levarage technologies flagged for Google only
        ],
    )

    return mctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = "all",
        root_module_direct_dev_deps = [],
    )

xla = module_extension(
    implementation = _xla_impl,
)
