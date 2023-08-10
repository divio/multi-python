# Multi-Python Image

This repository defines a Python image based on Ubuntu with multiple Python versions installed,
along with the `tox` executable. It is meant to use in CI for test purposes.


## Python versions

The list of Python versions to install is passed as arguments (see `Dockerfile`).
One Python version must be selected as "main" - it will be used to install `tox`.
Along with "regular" Python versions, one pypy version will also be installed.

**IMPORTANT**: Python versions must be available either in the official Ubuntu repositories or in
the [deadsnakes PPA](https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa). The PyPy version should
be available at https://www.pypy.org/download.html.

## Usage

Run the following from a terminal at the root of your Python project:
```bash
docker run --rm -it -v $(PWD):/app registry.gitlab.com/divio/incubator/multi-Python:latest tox
```