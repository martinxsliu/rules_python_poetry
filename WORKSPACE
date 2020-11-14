workspace(name = "rules_python_poetry")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz",
    sha256 = "b6d46438523a3ec0f3cead544190ee13223a52f6a6765a29eae7b7cc24cc83a0",
)

load("//:defs.bzl", "poetry_install_toolchain", "poetry_install", "py_archive")

poetry_install_toolchain(poetry_version = "1.0.10")

# Simple test

poetry_install(
    name = "simple_deps",
    pyproject_toml = "//tests/simple:pyproject.toml",
    poetry_lock = "//tests/simple:poetry.lock",
    dev = True,
)

# Multi test

py_archive(
    name = "multi_app_requests",
    archive = "//tests/multi/app/vendor:requests-2.25.0.tar.gz",
    strip_prefix = "requests-2.25.0",
)

py_archive(
    name = "multi_app_responses",
    url = "https://files.pythonhosted.org/packages/88/98/bf9e777a482ac076a6d75fad7d62b064f535244bf1771c3b2a7d41fd5920/responses-0.12.1.tar.gz",
    sha256 = "2e5764325c6b624e42b428688f2111fea166af46623cb0127c05f6afb14d3457",
    strip_prefix = "responses-0.12.1",
)

poetry_install(
    name = "multi_app_deps",
    pyproject_toml = "//tests/multi/app:pyproject.toml",
    poetry_lock = "//tests/multi/app:poetry.lock",
)

poetry_install(
    name = "multi_liba_deps",
    pyproject_toml = "//tests/multi/liba:pyproject.toml",
    poetry_lock = "//tests/multi/liba:poetry.lock",
)

poetry_install(
    name = "multi_libb_deps",
    pyproject_toml = "//tests/multi/libb:pyproject.toml",
    poetry_lock = "//tests/multi/libb:poetry.lock",
)
