BUILD_TMPL = """\
package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "py_library",
    srcs = glob(["**/*.py"]),
    data = glob(["**/*"], exclude=["**/*.py", "**/* *"]),
)
"""

def _py_archive_impl(repository_ctx):
    if repository_ctx.attr.url:
        repository_ctx.download_and_extract(
            url = repository_ctx.attr.url,
            sha256 = repository_ctx.attr.sha256,
            stripPrefix = repository_ctx.attr.strip_prefix,
        )
    elif repository_ctx.attr.archive:
        repository_ctx.extract(
            archive = repository_ctx.attr.archive,
            stripPrefix = repository_ctx.attr.strip_prefix,
        )
    else:
        fail("Either 'url' or 'archive' must be provided.")

    repository_ctx.file("BUILD.bazel", BUILD_TMPL)

py_archive = repository_rule(
    implementation = _py_archive_impl,
    attrs = {
        "url": attr.string(
            doc = "URL of the Python archive.",
        ),
        "sha256": attr.string(
            doc = "SHA256 hash of the downloaded archive file.",
        ),
        "archive": attr.label(
            allow_single_file = True,
            doc = "Label of the Python archive. Either 'url' or 'archive' must be provided.",
        ),
        "strip_prefix": attr.string(
            doc = "A directory prefix to strip from the extracted files.",
        ),
    },
)
