# Multi-Python Image

This repository defines a Python image based on Ubuntu with multiple Python versions installed,
along with the `tox` executable. It is meant to use in CI for test purposes.

It supports both ARM and AMD architectures.

## Python versions

The list of Python versions to install is passed as arguments (see `Dockerfile`).
One Python version must be selected as "main" - it will be used to install `tox`.
Along with "regular" Python versions, one pypy version will also be installed.

The main python version is set as the default in the container (`python` and `python3`).

**IMPORTANT**: Python versions must be available either in the official Ubuntu repositories or in
the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa). The PyPy version should
be available at https://www.pypy.org/download.html.

## Usage

Run the following from a terminal at the root of your Python project:
```bash
docker run --rm -it -v $(PWD):/app divio/multi-python:latest tox
```

The default user is `tox`. If you need to install extra dependencies, `tox` has sudo rights
so it is possible to run `sudo apt update && sudo apt install ...`.

## Development

After updating the Python versions in the `Dockerfile`, ensure you also update `test/tox.ini` to
reflect the change.

## About pip

As stated in https://packaging.python.org/en/latest/guides/installing-using-linux-tools/#debian-ubuntu:

> Recent Debian/Ubuntu versions have modified pip to use the “User Scheme” by default,
> which is a significant behavior change that can be surprising to some users.

In other words, pip now installs libraries and executables in `$HOME/.local` (or `/home/tox/.local`
in this image).

This has no impact, except when running commands as `sudo`. Just keep in mind the `root` user
doesn't have the same packages installed.
