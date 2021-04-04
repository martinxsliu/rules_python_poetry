load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "extract_wheels",
    srcs = [
        "__init__.py",
        "__main__.py",
    ],
    main = "__main__.py",
    deps = ["//internal/pip_install/extract_wheels/lib"],
)

filegroup(
    name = "distribution",
    srcs = glob(["*"]) + [
        "//internal/pip_install/extract_wheels/lib:distribution",
    ],
    visibility = ["//internal/pip_install:__subpackages__"],
)
