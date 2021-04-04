load("@rules_python//python:defs.bzl", "py_test")

_RUNNER_TMPL = """\
import sys

import pytest

if __name__ == "__main__":
    args = sys.argv[1:] + {args}
    sys.exit(pytest.main(args))
"""

def _generate_runner_impl(ctx):
    args = list(ctx.attr.pytest_args)
    for f in ctx.files.srcs:
        args.append(f.short_path)
    body = _RUNNER_TMPL.format(
        args = args,
    )

    ctx.actions.write(ctx.outputs.out, body)

    return [
        DefaultInfo(executable = ctx.outputs.out),
    ]

generate_runner = rule(
    implementation = _generate_runner_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = [".py"],
        ),
        "out": attr.output(
            mandatory = True,
        ),
        "pytest_args": attr.string_list(),
    },
)

def pytest_test(name, srcs, pytest_args = [], **kwargs):
    runner_name = name + "_runner"
    runner_src_name = runner_name + ".py"
    generate_runner(
        name = runner_name,
        srcs = srcs,
        out = runner_src_name,
        pytest_args = pytest_args,
    )
    py_test(
        name = name,
        srcs = srcs + [runner_src_name],
        main = runner_src_name,
        **kwargs,
    )
