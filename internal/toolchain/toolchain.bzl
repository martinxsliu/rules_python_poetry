DEFAULT_VERSION = "1.1.4"

BUILD_TMPL = """\
package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "poetry",
    srcs = ["bin/poetry"],
    data = glob(
        ["venv/**/*"],
        exclude = [
            # Exclude files with spaces in its name.
            # See: https://github.com/bazelbuild/bazel/issues/4327
            "venv/lib/python*/site-packages/setuptools/command/launcher manifest.xml",
            "venv/lib/python*/site-packages/setuptools/script*",
        ],
    ),
)
"""

BUILD_TMPL_LEGACY = """\
package(default_visibility = ["//visibility:public"])

sh_binary(
    name = "poetry",
    srcs = ["bin/poetry"],
    data = glob(["src/**"]),
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
    if version < "1.2":
        _legacy_install(repository_ctx)
        return

    repository_ctx.download(
        url = "https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py",
        sha256 = "b35d059be6f343ac1f05ae56e8eaaaebb34da8c92424ee00133821d7f11e3a9c",
        output = "install-poetry.py",
    )

    # Absolute path to the repository directory.
    repository_dir = str(repository_ctx.path("."))

    arguments = [
        "python",
        "install-poetry.py",
        "--preview",  # Enable preview versions
        "--version", version,
    ]
    result = repository_ctx.execute(arguments, environment = {
        "POETRY_HOME": repository_dir,
    })
    if result.return_code != 0:
        fail("failed to install Poetry:\n%s\n%s" % (result.stdout, result.stderr))

    for plugin in repository_ctx.attr.plugins:
        result = repository_ctx.execute(["bin/poetry", "plugin", "add", plugin])
        if result.return_code != 0:
            fail("failed to install Poetry plugin %s:\n%s\n%s" % (plugin, result.stdout, result.stderr))

    repository_ctx.file("BUILD.bazel", BUILD_TMPL)
    repository_ctx.template(
        "bin/strip_dependencies",
        repository_ctx.attr._strip_dependencies_py_tmpl,
        substitutions = {
            "{HASH_BANG}": "{}/venv/bin/python".format(repository_dir),
        },
        executable = True,
    )

def _legacy_install(repository_ctx):
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

    repository_ctx.file("BUILD.bazel", BUILD_TMPL_LEGACY)
    repository_ctx.template(
        "bin/poetry",
        repository_ctx.attr._poetry_runner_py_tmpl,
        executable = True,
    )
    repository_ctx.template(
        "bin/strip_dependencies",
        repository_ctx.attr._strip_dependencies_py_tmpl,
        substitutions = {
            "{HASH_BANG}": "/usr/bin/env python",
        },
        executable = True,
    )

_poetry_install_toolchain = repository_rule(
    implementation = _poetry_install_toolchain_impl,
    attrs = {
        "poetry_version": attr.string(
            default = DEFAULT_VERSION,
            doc = "Version of Poetry",
        ),
        "plugins": attr.string_list(
            doc = "List of plugins to install (requires Poetry>=1.2.0)",
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
