load("@bazel_gazelle//:def.bzl", _DEFAULT_LANGUAGES = "DEFAULT_LANGUAGES")
load("//internal/toolchain:toolchain.bzl", _poetry_install_toolchain = "poetry_install_toolchain")
load("//internal/pip_install:pip_repository.bzl", _pip_repository = "pip_repository")
load("//internal:export.bzl", _poetry_export = "poetry_export")
load("//internal:install.bzl", _poetry_install = "poetry_install")
load("//internal:py_archive.bzl", _py_archive = "py_archive")
load("//internal:pytest.bzl", _pytest_test = "pytest_test")

pip_repository = _pip_repository
poetry_install_toolchain = _poetry_install_toolchain
poetry_export = _poetry_export
poetry_install = _poetry_install
py_archive = _py_archive
pytest_test = _pytest_test

PYTHON_LANGUAGE = "@rules_python_poetry//internal/gazelle"
DEFAULT_LANGUAGES = _DEFAULT_LANGUAGES + [PYTHON_LANGUAGE]
