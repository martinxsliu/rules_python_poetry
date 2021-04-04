workspace(name = "rules_python_poetry")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    sha256 = "b6d46438523a3ec0f3cead544190ee13223a52f6a6765a29eae7b7cc24cc83a0",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz",
)

load("//internal/toolchain:toolchain.bzl", "poetry_install_toolchain")

poetry_install_toolchain(poetry_version = "1.1.4")

# Go rules for Gazelle

http_archive(
    name = "io_bazel_rules_go",
    sha256 = "69de5c704a05ff37862f7e0f5534d4f479418afc21806c887db544a316f3cb6b",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.27.0/rules_go-v0.27.0.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/v0.27.0/rules_go-v0.27.0.tar.gz",
    ],
)

http_archive(
    name = "bazel_gazelle",
    sha256 = "62ca106be173579c0a167deb23358fdfe71ffa1e4cfdddf5582af26520f1c66f",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.23.0/bazel-gazelle-v0.23.0.tar.gz",
        "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.23.0/bazel-gazelle-v0.23.0.tar.gz",
    ],
)

load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.16")

gazelle_dependencies()

load("//internal:install.bzl", "poetry_install")
load("//internal/pip_install:pip_repository.bzl", "pip_repository")
load("//internal:py_archive.bzl", "py_archive")

# Simple test

poetry_install(
    name = "simple_deps",
    dev = True,
    poetry_lock = "//tests/simple:poetry.lock",
    pyproject_toml = "//tests/simple:pyproject.toml",
)

# Multi test

py_archive(
    name = "multi_app_requests",
    archive = "//tests/multi/app/vendor:requests-2.25.0.tar.gz",
    strip_prefix = "requests-2.25.0",
)

py_archive(
    name = "multi_app_responses",
    sha256 = "2e5764325c6b624e42b428688f2111fea166af46623cb0127c05f6afb14d3457",
    strip_prefix = "responses-0.12.1",
    url = "https://files.pythonhosted.org/packages/88/98/bf9e777a482ac076a6d75fad7d62b064f535244bf1771c3b2a7d41fd5920/responses-0.12.1.tar.gz",
)

poetry_install(
    name = "multi_app_deps",
    poetry_lock = "//tests/multi/app:poetry.lock",
    pyproject_toml = "//tests/multi/app:pyproject.toml",
)

poetry_install(
    name = "multi_liba_deps",
    poetry_lock = "//tests/multi/liba:poetry.lock",
    pyproject_toml = "//tests/multi/liba:pyproject.toml",
)

poetry_install(
    name = "multi_libb_deps",
    poetry_lock = "//tests/multi/libb:poetry.lock",
    pyproject_toml = "//tests/multi/libb:pyproject.toml",
)

load("//tests/repo:repositories.bzl", "pip_repositories")

# gazelle:repository_macro tests/repo/repositories.bzl%pip_repositories
pip_repositories()

load("//:defs.bzl", "pip_repository")

pip_repository(
    name = "pypi__stdlib_list",
    package = "stdlib_list",
    requirement = "==0.8.0"
)
