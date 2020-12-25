load("//internal:providers.bzl", "PoetryPackageInfo")

_POETRY_PUBLISH_COMMAND = """\
export root="$(pwd)"
cd {project_dir}
rm -rf dist
mkdir dist
{copy_archives}
{poetry_cmd}
"""

def _poetry_publish_impl(ctx):
    package_info = ctx.attr.package[PoetryPackageInfo]

    poetry_cmd = [
        "$root/" + ctx.executable._poetry.short_path,
        "publish",
        "-vvv",
    ]
    files = package_info.output_formats.values() + [package_info.pyproject_toml]

    if ctx.attr.repository:
        poetry_cmd.append("--repository=" + ctx.attr.repository)
    if ctx.attr.username:
        poetry_cmd.append("--username=" + ctx.attr.username)
    if ctx.attr.password:
        poetry_cmd.append("--password=" + ctx.attr.password)
    if ctx.attr.ca_cert:
        poetry_cmd.append("--cert=" + ctx.attr.ca_cert.short_path)
        files.append(ctx.file.ca_cert)
    if ctx.attr.client_cert:
        poetry_cmd.append("--client-cert=" + ctx.attr.client_cert.short_path)
        files.append(ctx.file.client_cert)

    copy_archives = []
    for output in package_info.output_formats.values():
        copy_archives.append('cp "$root/%s" dist' % output.short_path)

    script = _POETRY_PUBLISH_COMMAND.format(
        project_dir = package_info.pyproject_toml.dirname,
        copy_archives = "\n".join(copy_archives),
        poetry_cmd = " ".join(poetry_cmd),
    )

    output = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(output, script)

    runfiles = ctx.runfiles(
        files = files,
        transitive_files = ctx.attr._poetry.default_runfiles.files,
    )

    return [
        DefaultInfo(
            executable = output,
            runfiles = runfiles,
        ),
    ]

poetry_publish = rule(
    implementation = _poetry_publish_impl,
    executable = True,
    attrs = {
        "package": attr.label(
            mandatory = True,
            doc = "Poetry package to publish",
            providers = [PoetryPackageInfo],
        ),
        "repository": attr.string(
            doc = "Repository to publish to, defaults to PyPI",
        ),
        "username": attr.string(
            doc = "Username to access the repository",
        ),
        "password": attr.string(
            doc = "Password to access the repository",
        ),
        "ca_cert": attr.label(
            allow_single_file = True,
            doc = "Certificate authority to access the repository",
        ),
        "client_cert": attr.label(
            allow_single_file = True,
            doc = "Client certificate to access the repository",
        ),
        "_poetry": attr.label(
            default = "@poetry_toolchain//:poetry",
            executable = True,
            cfg = "exec",
        ),
    },
)
