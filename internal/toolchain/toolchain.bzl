DEFAULT_VERSION = "1.0.10"

SHA256_SUMS = {
    "1.1.4": {
        "darwin": "1b472604c72fbd1a567e238984f3306efd2b0e5b49271f7bae17a1f5057eb547",
        "freebsd13": "6e4032ed3d9d9dd34de48f63b1ac4131c44b557a65d6c30a37c3fb0e39e1a474",
        "linux": "461594ce704b63cb2290597a9f33a18106ce0bf0345b908278dfefa5d5fa60dd",
        "win32": "b46cd8a9d581fcc51fbeb5a92967e771f3f36d0187cfff3cdaa0c2d837c2721e",
    },
    "1.0.10": {
        "darwin": "f5213808baa5fd3244dfa577eb85f570d9f33f031092ad0424b5d8267e84d370",
        "linux": "b5a5441f9714e21eaffec3d67ffeaa81d5df5cc232efffce8d06b8f56599c0e9",
        "win32": "5c60560f7c1b234b0ee0bb170c7d8402550e0ce129afee18fb06505e543cbc05",
    },
}

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
    if version not in SHA256_SUMS:
        fail("Unsupported Poetry version \"{}\", supported versions are {}".format(version, sorted(SHA256_SUMS.keys())))

    platform = _get_platform(repository_ctx)
    if platform not in SHA256_SUMS[version]:
        fail("Platform \"{}\" is not supported on version \"{}\", try a newer version".format(platform, version))

    sha256 = SHA256_SUMS[version][platform]
    url = "https://github.com/python-poetry/poetry/releases/download/{version}/poetry-{version}-{platform}.tar.gz".format(
        version = version,
        platform = platform,
    )

    repository_ctx.download_and_extract(
        url = url,
        sha256 = sha256,
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
