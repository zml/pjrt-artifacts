load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("xla.bzl", "OPENXLA_COMMIT")
load("@aspect_bazel_lib//lib:tar.bzl", "tar")

def create_openxla_targets():
    # List of configurations
    configs = [
        {"name": "cuda"},
        {"name": "rocm"},
    ]

    # Loop to create the pkg_tar rules
    for config in configs:
        pkg_tar(
            name = "xla_configure_{}".format(config["name"]),
            srcs = [
                "{}.bazelrc".format(config["name"]),
            ],
            package_dir = "xla-{}/".format(OPENXLA_COMMIT),
        )
        
        tar(
            name = "symlinks_{}".format(config["name"]),
            mtree = [
                "xla type=link link=/xla-{}".format(OPENXLA_COMMIT),
                "xla-{}/xla_configure.bazelrc type=link link=/xla-{}/{}.bazelrc".format(OPENXLA_COMMIT,OPENXLA_COMMIT,config["name"]),
            ],
        )

        pkg_tar(
            name = "openxla_layer_{}".format(config["name"]),
            deps = [
                "@openxla//file",
                ":symlinks_{}".format(config["name"]),
                ":xla_configure_{}".format(config["name"]),
                
            ],
            extension = "tar.gz",
            visibility = ["//visibility:public"],
        )

