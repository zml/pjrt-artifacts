load("@aspect_bazel_lib//lib:copy_directory.bzl", "copy_directory")
load("@aspect_bazel_lib//lib:tar.bzl", "tar", "mtree_spec", "mtree_mutate")
load("xla.bzl", "OPENXLA_COMMIT")

def create_openxla_targets():
    # List of configurations
    configs = [
        {"name": "cuda"},
        {"name": "rocm"},
        {"name": "cpu"},
    ]
    
    copy_directory(
        name = "openxla_subpackage_to_directory",
        src = "@openxla//:all_files",
        out = "xla-{}".format(OPENXLA_COMMIT),
    )

    mtree_spec(
        name = "openxla_subpackage_mtree",
        srcs = [":openxla_subpackage_to_directory"],
    )

    mtree_mutate(
        name = "openxla_mtree",
        mtree = ":openxla_subpackage_mtree",
        strip_prefix = "third_party/openxla",
    )

    tar(
        name = "openxla_tar",
        srcs = [":openxla_subpackage_to_directory"],
        mtree = ":openxla_mtree",
        visibility = ["//visibility:public"],
    )

    # Loop to create the config tar rules
    for config in configs:
        tar(
            name = "{}_configuration_tar".format(config["name"]),
            srcs = [
                ":common.bazelrc",
                "{}.bazelrc".format(config["name"]),
            ],
            mtree = [
                "xla-{}/common.bazelrc type=file content=third_party/openxla/common.bazelrc".format(OPENXLA_COMMIT),
                "xla-{}/xla_configure.bazelrc type=file content=third_party/openxla/{}.bazelrc".format(OPENXLA_COMMIT, config["name"]),
                "xla type=link link=/xla-{}".format(OPENXLA_COMMIT),
            ],
            visibility = ["//visibility:public"],
        )
