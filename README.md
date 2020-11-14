# rules_python_poetry

Bazel rules to install Python dependencies from a [Poetry](https://python-poetry.org/) project.
Works with native Python rules for Bazel.

## Getting started

Add the following to your `WORKSPACE` file:

```py
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_python",
    url = "https://github.com/bazelbuild/rules_python/releases/download/0.1.0/rules_python-0.1.0.tar.gz",
    sha256 = "b6d46438523a3ec0f3cead544190ee13223a52f6a6765a29eae7b7cc24cc83a0",
)

http_archive(
    name = "rules_python_poetry",
    url = "TODO",
    sha256 = "TODO",
)

load("@rules_python_poetry//:defs.bzl", "poetry_install_toolchain", "poetry_install")

# Optional, if you want to use a specific version of Poetry (1.0.10 is the default).
poetry_install_toolchain(poetry_version = "1.1.4")

poetry_install(
    name = "my_deps",
    pyproject_toml = "//path/to:pyproject.toml",
    poetry_lock = "//path/to:poetry.lock",
    dev = True,  # Optional
)
```

Under the hood, `poetry_install` uses Poetry to export a `requirements.txt` file which is then passed to [`rule_python`'s `pip_install` repository rule](https://github.com/bazelbuild/rules_python#importing-pip-dependencies).
You can consume dependencies the same way as you would with `pip_install`, e.g.:

```py
load("@my_deps//:requirements.bzl", "requirement")

py_library(
    name = "my_lib",
    srcs = ["my_lib.py"],
    deps = [
        ":my_other_lib",
        requirement("some_pip_dep"),
        requirement("another_pip_dep[some_extra]"),
    ],
)
```

## Poetry dependencies

Poetry allows you to specify dependencies from different types of sources that are not automatically fetched and installed by the `poetry_install` rule. You will have to manually declare these dependencies.

See [`tests/multi/app`](tests/multi/app) for examples.

### Local directory dependency

A dependency on a local directory, for example if you have multiple projects within a monorepo that depend on each other.

```toml
[tool.poetry.dependencies]
foo = {path = "../libs/foo"}
```

If the local dependency has a `py_library` target, you can include it in the `deps` attribute.

```py
py_library(
    name = "my_lib",
    srcs = ["my_lib.py"],
    deps = [
        "//path/to/libs:foo",
    ],
)
```

### Local file dependency

A dependency on a local tarball, for example if you have vendored packages.

```toml
[tool.poetry.dependencies]
foo = {path = "../vendor/foo-1.2.3.tar.gz"}
```

There are some options available.
The first is to extract the archive and vendor the extracted files. Then add a `py_library` that can be included as a `deps`, like the local directory dependency.

The second is to use the `py_archive` repository rule to declare the archive as an external repository in your `WORKSPACE` file, e.g.:

```py
load("@rules_python_poetry//:defs.bzl", "py_archive")

py_archive(
    name = "foo",
    archive = "//path/to/vendor:foo-1.2.3.tar.gz",
    strip_prefix = "foo-1.2.3",
)
```

The `py_archive` rule defines a target named `:py_library` that can be referenced like so:

```py
py_library(
    name = "my_lib",
    srcs = ["my_lib.py"],
    deps = [
        "@foo//:py_library",
    ],
)
```

### URL dependency

A dependency on a remote archive.

```toml
[tool.poetry.dependencies]
foo = {url = "https://example.com/packages/foo-1.2.3.tar.gz"}
```

You can use the `py_archive` repository rule to declare the remote archive as an external repository in your `WORKSPACE` file, e.g.:

```py
load("@rules_python_poetry//:defs.bzl", "py_archive")

py_archive(
    name = "foo",
    url = "https://example.com/packages/foo-1.2.3.tar.gz",
    sha256 = "...",
    strip_prefix = "foo-1.2.3",
)
```

The `py_archive` rule defines a target named `:py_library` that can be referenced like so:

```py
py_library(
    name = "my_lib",
    srcs = ["my_lib.py"],
    deps = [
        "@foo//:py_library",
    ],
)
```

### Git dependency

Git dependencies are not currently supported. You can work around this by using a URL dependency instead of a git key.
