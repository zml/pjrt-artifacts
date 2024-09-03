load("@aspect_bazel_lib//lib:tar.bzl", "mtree_spec", "tar", "tar_lib")

# Basic implementation, we need to build a better solution
# Effect of this is the effective build of a 30Gb image
# will require at least 2x+ the disk space to make it work. 
def _dedupe_tar_impl(ctx):
    """
    Remove duplicate entries in a tarball

    This is kinda a hack: extract the mtree file, explode the tarball (handled
    overwriting the files), then recreate the tarball from the exploded tree.

    This has the effect of removing duplicate entries from the tarball
    """
    bsdtar = ctx.toolchains[tar_lib.toolchain_type]
    bsdtar_bin = bsdtar.template_variables.variables["BSDTAR_BIN"]
    src = ctx.file.src

    output_tar = ctx.actions.declare_file("%s_d.tar.zst" % ctx.label.name)

    filter = ctx.file.filter
    if filter == None:
        filter = ctx.actions.declare_file("all.txt")
        ctx.actions.run_shell(
            inputs = [],
            outputs = [filter],
            command = """
                echo "" > {filter}
            """.format(
                filter = filter.path
            )
        )
   
    strip_directory = ctx.attr.strip_directory

    ctx.actions.run_shell(
        outputs = [output_tar],
        inputs = [src, filter],
        # sed osx is a pain with -i and symbolic links
        command = """
            set -eu
            export TMP=$(mktemp -d || mktemp -d -t bazel-tmp)
            trap "rm -rf $TMP" EXIT
            mkdir $TMP/extracted
            sed "s|^|.|g" {filter} > tmp.txt
            mv tmp.txt {filter}
            {bsdtar} -xf {src} -C $TMP/extracted
            {bsdtar} -C $TMP/extracted --strip-components={strip_directory} -caf {output} -T {filter}
        """.format(
            bsdtar = bsdtar_bin,
            src = src.path,
            output = output_tar.path,
            mtree = "$TMP/mtree.txt",
            strip_directory = strip_directory,
            filter = filter.path,
        ),
        tools = [bsdtar.default.files],
    )

    return DefaultInfo(files = depset([output_tar]))

dedupe_tar = rule(
    implementation = _dedupe_tar_impl,
    attrs = {
        "src": attr.label(mandatory = True, allow_single_file = True),
        "filter": attr.label(mandatory = False, allow_single_file = True),
        "strip_directory": attr.int(default = 0),
    },
    # XXX: side effect: gzipping the output 
    outputs = {"output_tar": "%{name}_d.tar.zst"},
    toolchains = [tar_lib.toolchain_type],
)