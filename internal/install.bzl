load("@rules_python//python:pip.bzl", "pip_install")
load("//internal/toolchain:toolchain.bzl", "poetry_install_toolchain")
load("//internal:export.bzl", "poetry_export")

def poetry_install(name, pyproject_toml, poetry_lock, dev = False, **kwargs):
    if "poetry_toolchain" not in native.existing_rules().keys():
        poetry_install_toolchain()

    export_name = name + "_export"
    poetry_export(
        name = export_name,
        pyproject_toml = pyproject_toml,
        poetry_lock = poetry_lock,
        dev = dev,
    )

    pip_install(
        name = name,
        requirements = "@{}//:requirements.txt".format(export_name),
        **kwargs,
    )
