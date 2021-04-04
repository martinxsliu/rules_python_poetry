load("@rules_python_poetry//:defs.bzl", "pip_repository")

def pip_repositories():
    pip_repository(
        name = "pypi__appnope",
        extra_pip_args = ["--foo", "--bar"],
        package = "appnope",
        requirement = "==0.1.2",
    )
    pip_repository(
        name = "pypi__asgiref",
        extra_pip_args = ["--foo", "--bar"],
        package = "asgiref",
        requirement = "==3.3.1",
    )
    pip_repository(
        name = "pypi__atomicwrites",
        extra_pip_args = ["--foo", "--bar"],
        package = "atomicwrites",
        requirement = "==1.4.0",
    )
    pip_repository(
        name = "pypi__attrs",
        extra_pip_args = ["--foo", "--bar"],
        package = "attrs",
        requirement = "==20.3.0",
    )
    pip_repository(
        name = "pypi__backcall",
        extra_pip_args = ["--foo", "--bar"],
        package = "backcall",
        requirement = "==0.2.0",
    )
    pip_repository(
        name = "pypi__certifi",
        extra_pip_args = ["--foo", "--bar"],
        package = "certifi",
        requirement = "==2020.12.5",
    )
    pip_repository(
        name = "pypi__chardet",
        extra_pip_args = ["--foo", "--bar"],
        package = "chardet",
        requirement = "==4.0.0",
    )
    pip_repository(
        name = "pypi__colorama",
        extra_pip_args = ["--foo", "--bar"],
        package = "colorama",
        requirement = "==0.4.4",
    )
    pip_repository(
        name = "pypi__decorator",
        extra_pip_args = ["--foo", "--bar"],
        package = "decorator",
        requirement = "==5.0.5",
    )
    pip_repository(
        name = "pypi__django",
        extra_pip_args = ["--foo", "--bar"],
        package = "django",
        requirement = "==3.1.7",
    )
    pip_repository(
        name = "pypi__idna",
        extra_pip_args = ["--foo", "--bar"],
        package = "idna",
        requirement = "==2.10",
    )
    pip_repository(
        name = "pypi__iniconfig",
        extra_pip_args = ["--foo", "--bar"],
        package = "iniconfig",
        requirement = "==1.1.1",
    )
    pip_repository(
        name = "pypi__ipython",
        extra_pip_args = ["--foo", "--bar"],
        package = "ipython",
        requirement = "==7.22.0",
    )
    pip_repository(
        name = "pypi__ipython_genutils",
        extra_pip_args = ["--foo", "--bar"],
        package = "ipython_genutils",
        requirement = "==0.2.0",
    )
    pip_repository(
        name = "pypi__jedi",
        extra_pip_args = ["--foo", "--bar"],
        package = "jedi",
        requirement = "==0.18.0",
    )
    pip_repository(
        name = "pypi__numpy",
        extra_pip_args = ["--foo", "--bar"],
        package = "numpy",
        requirement = "==1.20.2",
    )
    pip_repository(
        name = "pypi__packaging",
        extra_pip_args = ["--foo", "--bar"],
        package = "packaging",
        requirement = "==20.9",
    )
    pip_repository(
        name = "pypi__pandas",
        extra_pip_args = ["--foo", "--bar"],
        package = "pandas",
        requirement = "==1.2.3",
    )
    pip_repository(
        name = "pypi__parso",
        extra_pip_args = ["--foo", "--bar"],
        package = "parso",
        requirement = "==0.8.2",
    )
    pip_repository(
        name = "pypi__pendulum",
        extra_pip_args = ["--foo", "--bar"],
        package = "pendulum",
        requirement = "==2.1.2",
    )
    pip_repository(
        name = "pypi__pexpect",
        extra_pip_args = ["--foo", "--bar"],
        package = "pexpect",
        requirement = "==4.8.0",
    )
    pip_repository(
        name = "pypi__pickleshare",
        extra_pip_args = ["--foo", "--bar"],
        package = "pickleshare",
        requirement = "==0.7.5",
    )
    pip_repository(
        name = "pypi__pluggy",
        extra_pip_args = ["--foo", "--bar"],
        package = "pluggy",
        requirement = "==0.13.1",
    )
    pip_repository(
        name = "pypi__prompt_toolkit",
        extra_pip_args = ["--foo", "--bar"],
        package = "prompt_toolkit",
        requirement = "==3.0.18",
    )
    pip_repository(
        name = "pypi__ptyprocess",
        extra_pip_args = ["--foo", "--bar"],
        package = "ptyprocess",
        requirement = "==0.7.0",
    )
    pip_repository(
        name = "pypi__py",
        extra_pip_args = ["--foo", "--bar"],
        package = "py",
        requirement = "==1.10.0",
    )
    pip_repository(
        name = "pypi__pygments",
        extra_pip_args = ["--foo", "--bar"],
        package = "pygments",
        requirement = "==2.8.1",
    )
    pip_repository(
        name = "pypi__pyparsing",
        extra_pip_args = ["--foo", "--bar"],
        package = "pyparsing",
        requirement = "==2.4.7",
    )
    pip_repository(
        name = "pypi__pytest",
        extra_pip_args = ["--foo", "--bar"],
        package = "pytest",
        requirement = "==6.2.3",
    )
    pip_repository(
        name = "pypi__python_dateutil",
        extra_pip_args = ["--foo", "--bar"],
        package = "python_dateutil",
        requirement = "==2.8.1",
    )
    pip_repository(
        name = "pypi__pytz",
        extra_pip_args = ["--foo", "--bar"],
        package = "pytz",
        requirement = "==2021.1",
    )
    pip_repository(
        name = "pypi__pytzdata",
        extra_pip_args = ["--foo", "--bar"],
        package = "pytzdata",
        requirement = "==2020.1",
    )
    pip_repository(
        name = "pypi__requests",
        extra_pip_args = ["--foo", "--bar"],
        package = "requests",
        requirement = "==2.25.1",
    )
    pip_repository(
        name = "pypi__six",
        extra_pip_args = ["--foo", "--bar"],
        package = "six",
        requirement = "==1.15.0",
    )
    pip_repository(
        name = "pypi__sqlparse",
        extra_pip_args = ["--foo", "--bar"],
        package = "sqlparse",
        requirement = "==0.4.1",
    )
    pip_repository(
        name = "pypi__toml",
        extra_pip_args = ["--foo", "--bar"],
        package = "toml",
        requirement = "==0.10.2",
    )
    pip_repository(
        name = "pypi__traitlets",
        extra_pip_args = ["--foo", "--bar"],
        package = "traitlets",
        requirement = "==5.0.5",
    )
    pip_repository(
        name = "pypi__urllib3",
        extra_pip_args = ["--foo", "--bar"],
        package = "urllib3",
        requirement = "==1.26.4",
    )
    pip_repository(
        name = "pypi__wcwidth",
        extra_pip_args = ["--foo", "--bar"],
        package = "wcwidth",
        requirement = "==0.2.5",
    )
