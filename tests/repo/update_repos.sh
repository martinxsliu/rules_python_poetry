#!/usr/bin/env bash

bazel run //:gazelle -- update-repos \
  -from_file=tests/repo/poetry.lock \
  -to_macro=tests/repo/repositories.bzl%pip_repositories \
  -extra_pip_args=--foo \
  -extra_pip_args=--bar \
  -prune
