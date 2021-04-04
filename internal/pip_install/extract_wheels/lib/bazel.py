"""Utility functions to manipulate Bazel files"""
import os
import textwrap
import json
from typing import Iterable, List, Dict, Set
import shutil

from internal.pip_install.extract_wheels.lib import namespace_pkgs, wheel, purelib

PY_LIBRARY_TARGET = "lib"
WHEEL_FILE_TARGET = "whl"

def generate_build_file_contents(
    name: str, dependencies: List[str], whl_file_deps: List[str], pip_data_exclude: List[str],
) -> str:
    """Generate a BUILD file for an unzipped Wheel

    Args:
        name: the target name of the py_library
        dependencies: a list of Bazel labels pointing to dependencies of the library
        whl_file_deps: a list of Bazel labels pointing to wheel file dependencies of this wheel.

    Returns:
        A complete BUILD file as a string

    We allow for empty Python sources as for Wheels containing only compiled C code
    there may be no Python sources whatsoever (e.g. packages written in Cython: like `pymssql`).
    """

    data_exclude = ["*.whl", "**/*.py", "**/* *", "BUILD", "WORKSPACE"] + pip_data_exclude

    return textwrap.dedent(
        """\
        package(default_visibility = ["//visibility:public"])

        load("@rules_python//python:defs.bzl", "py_library")

        filegroup(
            name = "{whl_file_label}",
            srcs = glob(["*.whl"]),
            data = [{whl_file_deps}],
        )

        py_library(
            name = "{name}",
            srcs = glob(["**/*.py"], allow_empty = True),
            data = glob(["**/*"], exclude={data_exclude}),
            # This makes this directory a top-level in the python import
            # search path for anything that depends on this.
            imports = ["."],
            deps = [{dependencies}],
        )
        """.format(
            name=name,
            dependencies=", ".join(dependencies),
            data_exclude=json.dumps(data_exclude),
            whl_file_label=WHEEL_FILE_TARGET,
            whl_file_deps=", ".join(whl_file_deps),
        )
    )


def generate_requirements_file_contents(repo_name: str, targets: Iterable[str]) -> str:
    """Generate a requirements.bzl file for a given pip repository

    The file allows converting the PyPI name to a bazel label. Additionally, it adds a function which can glob all the
    installed dependencies.

    Args:
        repo_name: the name of the pip repository
        targets: a list of Bazel labels pointing to all the generated targets

    Returns:
        A complete requirements.bzl file as a string
    """

    sorted_targets = sorted(targets)
    requirement_labels = ",".join(sorted_targets)
    whl_requirement_labels = ",".join(
        '"{}:whl"'.format(target.strip('"')) for target in sorted_targets
    )
    return textwrap.dedent(
        """\
        all_requirements = [{requirement_labels}]

        all_whl_requirements = [{whl_requirement_labels}]

        def requirement(name):
           name_key = name.replace("-", "_").replace(".", "_").lower()
           return "{repo}//pypi__" + name_key

        def whl_requirement(name):
            return requirement(name) + ":whl"
        """.format(
            repo=repo_name,
            requirement_labels=requirement_labels,
            whl_requirement_labels=whl_requirement_labels,
        )
    )


def sanitise_name(name: str) -> str:
    """Sanitises the name to be compatible with Bazel labels.

    There are certain requirements around Bazel labels that we need to consider. From the Bazel docs:

        Package names must be composed entirely of characters drawn from the set A-Z, a–z, 0–9, '/', '-', '.', and '_',
        and cannot start with a slash.

    Due to restrictions on Bazel labels we also cannot allow hyphens. See
    https://github.com/bazelbuild/bazel/issues/6841

    Further, rules-python automatically adds the repository root to the PYTHONPATH, meaning a package that has the same
    name as a module is picked up. We workaround this by prefixing with `pypi__`. Alternatively we could require
    `--noexperimental_python_import_all_repositories` be set, however this breaks rules_docker.
    See: https://github.com/bazelbuild/bazel/issues/2636
    """

    return "pypi__" + name.replace("-", "_").replace(".", "_").lower()


def sanitise_dep_label(single_file_mode: bool, name: str, whl: bool) -> str:
    sanitised_name = sanitise_name(name)
    if single_file_mode:
        repo = "@" + sanitised_name
        package = ""
        target = ":" + PY_LIBRARY_TARGET
    else:
        repo = ""
        package = sanitised_name
        target = ""
    if whl:
        target = ":" + WHEEL_FILE_TARGET
    return '"{}//{}{}"'.format(repo, package, target)


def setup_namespace_pkg_compatibility(wheel_dir: str) -> None:
    """Converts native namespace packages to pkgutil-style packages

    Namespace packages can be created in one of three ways. They are detailed here:
    https://packaging.python.org/guides/packaging-namespace-packages/#creating-a-namespace-package

    'pkgutil-style namespace packages' (2) and 'pkg_resources-style namespace packages' (3) works in Bazel, but
    'native namespace packages' (1) do not.

    We ensure compatibility with Bazel of method 1 by converting them into method 2.

    Args:
        wheel_dir: the directory of the wheel to convert
    """

    namespace_pkg_dirs = namespace_pkgs.implicit_namespace_packages(
        wheel_dir, ignored_dirnames=["%s/bin" % wheel_dir,],
    )

    for ns_pkg_dir in namespace_pkg_dirs:
        namespace_pkgs.add_pkgutil_style_namespace_pkg_init(ns_pkg_dir)


def extract_wheel(
    wheel_file: str,
    extras: Dict[str, Set[str]],
    pip_data_exclude: List[str],
    enable_implicit_namespace_pkgs: bool,
    single_package_mode: bool,
) -> str:
    """Extracts wheel into given directory and creates py_library and filegroup targets.

    Args:
        wheel_file: the filepath of the .whl
        extras: a list of extras to add as dependencies for the installed wheel
        pip_data_exclude: list of file patterns to exclude from the generated data section of the py_library
        enable_implicit_namespace_pkgs: if true, disables conversion of implicit namespace packages and will unzip as-is
        single_package_mode:

    Returns:
        The Bazel label for the extracted wheel, in the form '//path/to/wheel'.
    """

    whl = wheel.Wheel(wheel_file)

    if single_package_mode:
        directory = "."
    else:
        directory = sanitise_name(whl.name)
        os.mkdir(directory)
        # copy the original wheel
        shutil.copy(whl.path, directory)

    whl.unzip(directory)

    # Note: Order of operations matters here
    purelib.spread_purelib_into_root(directory)

    if not enable_implicit_namespace_pkgs:
        setup_namespace_pkg_compatibility(directory)

    extras_requested = extras[whl.name] if whl.name in extras else set()
    whl_deps = sorted(whl.dependencies(extras_requested))

    sanitised_dependencies = [
        sanitise_dep_label(single_package_mode, d, False) for d in whl_deps
    ]
    sanitised_wheel_file_dependencies = [
        sanitise_dep_label(single_package_mode, d, True) for d in whl_deps
    ]

    py_library_name = PY_LIBRARY_TARGET if single_package_mode else sanitise_name(whl.name)
    with open(os.path.join(directory, "BUILD"), "w") as build_file:
        contents = generate_build_file_contents(
            py_library_name, sanitised_dependencies, sanitised_wheel_file_dependencies, pip_data_exclude
        )
        build_file.write(contents)

    if not single_package_mode:
        os.remove(whl.path)

    if single_package_mode:
        return "//:whl"
    return "//%s" % directory
