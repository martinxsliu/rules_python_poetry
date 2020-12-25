load("//internal:providers.bzl", "PoetryPackageInfo")

_POETRY_BUILD_COMMAND = """\
export root="$(pwd)"
cd {package_dir}
"$root/{poetry}" build -vvv --format={format} --dist-dir=dist > stdout.log
if [ $? -ne 0 ]; then
  cat stdout.log
  exit 1
fi
mv dist/* "$root/{output}"
"""

def _poetry_package_impl(ctx):
    output_formats = {}

    depsets = []
    for dep in ctx.attr.deps:
        depsets.append(dep.data_runfiles.files)

    for format in ctx.attr.formats:
        output_name = ctx.label.name
        if format == "wheel":
            output_name += ".whl"
        elif format == "sdist":
            output_name += ".tar.gz"
        else:
            fail("format must be either 'wheel' or 'sdist'")

        output = ctx.actions.declare_file(output_name)
        output_formats[format] = output

        command = _POETRY_BUILD_COMMAND.format(
            package_dir = ctx.file.pyproject_toml.dirname,
            poetry = ctx.executable._poetry.path,
            format = format,
            output = output.path,
        )
        ctx.actions.run_shell(
            outputs = [output],
            inputs = depset([ctx.file.pyproject_toml, ctx.file.poetry_lock], transitive=depsets),
            tools = [ctx.executable._poetry],
            command = command,
            mnemonic = "PoetryBuildPackage",
        )

    return [
        PoetryPackageInfo(
            pyproject_toml = ctx.file.pyproject_toml,
            poetry_lock = ctx.file.poetry_lock,
            output_formats = output_formats,
        ),
        DefaultInfo(
            files = depset(output_formats.values()),
        ),
    ]

poetry_package = rule(
    implementation = _poetry_package_impl,
    attrs = {
        "pyproject_toml": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Label of the project's pyproject.toml file",
        ),
        "poetry_lock": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Label of the project's poetry.lock file",
        ),
        "deps": attr.label_list(
            mandatory = True,
            doc = "Label of the project's poetry.lock file",
        ),
        "formats": attr.string_list(
            default = ["wheel", "sdist"],
            doc = "Format of archives to build, either 'wheel' or 'sdist'.",
        ),
        "_poetry": attr.label(
            default = "@poetry_toolchain//:poetry",
            executable = True,
            cfg = "exec",
        ),
    },
)
