DEFAULT_VERSION = "1.1.4"

BUILD_TMPL = """\
package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "poetry",
    srcs = glob(["src/**/*.py"]) + ["poetry_runner.py"],
    data = glob(["src/**/*"], exclude=["src/**/*.py", "src/**/* *"]),
    main = "poetry_runner.py",
    legacy_create_init = False,
)
"""

def _get_platform(repository_ctx):
    if repository_ctx.os.name == "linux":
        return "linux"
    elif repository_ctx.os.name == "mac os x":
        return "darwin"
    elif repository_ctx.os.name.startswith("windows"):
        return "win32"
    elif repository_ctx.os.name == "freebsd":
        return "freebsd13"
    fail("Platform \"{}\" is not supported".format(repository_ctx.os.name))

def _poetry_install_toolchain_impl(repository_ctx):
    version = repository_ctx.attr.poetry_version
    platform = _get_platform(repository_ctx)

    sha256sum_url = "https://github.com/python-poetry/poetry/releases/download/{version}/poetry-{version}-{platform}.sha256sum".format(
        version = version,
        platform = platform,
    )
    repository_ctx.download(url = sha256sum_url, output = "sha256sum")
    sha256sum = repository_ctx.read("sha256sum")

    url = "https://github.com/python-poetry/poetry/releases/download/{version}/poetry-{version}-{platform}.tar.gz".format(
        version = version,
        platform = platform,
    )
    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256sum,
        # Place files inside a "src" directory so that the ":poetry" target is
        # not a prefix of its data dependencies.
        # See: https://github.com/bazelbuild/bazel/issues/12312
        output = "src",
    )

    repository_ctx.file("BUILD.bazel", BUILD_TMPL)
    repository_ctx.template("poetry_runner.py", repository_ctx.attr._poetry_runner_py_tmpl)
    repository_ctx.template("strip_dependencies.py", repository_ctx.attr._strip_dependencies_py_tmpl)

_poetry_install_toolchain = repository_rule(
    implementation = _poetry_install_toolchain_impl,
    attrs = {
        "poetry_version": attr.string(
            default = DEFAULT_VERSION,
            doc = "Version of Poetry",
        ),
        "_poetry_runner_py_tmpl": attr.label(
            default = "//internal/toolchain:poetry_runner.py.tmpl",
        ),
        "_strip_dependencies_py_tmpl": attr.label(
            default = "//internal/toolchain:strip_dependencies.py.tmpl",
        ),
    },
)

def poetry_install_toolchain(**kwargs):
    _poetry_install_toolchain(
        name = "poetry_toolchain",
        **kwargs,
    )
