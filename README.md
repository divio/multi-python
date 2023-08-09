# Multi-Python Image

This repository defines a Python image based on Ubuntu with multiple Python versions installed,
along with the `tox` executable. It is meant to use in CI for test purposes.


## Supported Python versions

The list of Python versions is passed as an argument to the Docker image, see `Dockerfile`. The
first version of the list is used as the default Python (used by tox).