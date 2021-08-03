def _poetry_export_impl(repository_ctx):
    poetry_runner = repository_ctx.path(Label("@poetry_toolchain//:bin/poetry"))
    strip_dependencies = repository_ctx.path(Label("@poetry_toolchain//:bin/strip_dependencies"))

    repository_ctx.symlink(repository_ctx.attr.pyproject_toml, repository_ctx.path("pyproject.toml.in"))
    repository_ctx.symlink(repository_ctx.attr.poetry_lock, repository_ctx.path("poetry.lock.in"))

    for format in ["pyproject.toml", "poetry.lock"]:
        result = repository_ctx.execute([
            strip_dependencies,
            "--file",
            repository_ctx.path(format + ".in"),
            "--output",
            repository_ctx.path(format),
            "--format",
            format,
        ])
        if result.return_code:
            fail("Poetry strip dependencies failed:\n%s\n%s" % (result.stdout, result.stderr))

    args = [
        poetry_runner,
        "export",
        "--without-hashes",
        "--format",
        repository_ctx.attr.format,
        "--output",
        repository_ctx.path(repository_ctx.attr.format),
    ]
    if repository_ctx.attr.dev:
        args.append("--dev")

    result = repository_ctx.execute(args)
    if result.return_code:
        fail("Poetry export to requirements.txt failed:\n%s\n%s" % (result.stdout, result.stderr))

    repository_ctx.file("BUILD.bazel")

poetry_export = repository_rule(
    implementation = _poetry_export_impl,
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
        "dev": attr.bool(
            default = False,
            doc = "Include development dependencies",
        ),
        "format": attr.string(
            default = "requirements.txt",
            doc = "Format to export to. Currently, only requirements.txt is supported.",
        ),
    },
)
