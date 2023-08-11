FROM ubuntu:22.04

## Main python version to install + use for tox
ARG PYTHON_MAIN_VERSION=3.11
## Other python versions to install
# Must be available either in the deadsnakes PPA or in
# the official Ubuntu repositories
ARG PYTHON_VERSIONS="3.7 3.8 3.9 3.10"
## PyPy version to install
# for versions see https://www.pypy.org/download.html
ARG PYTHON_PYPY_VERSION=3.9-v7.3.12
## GPG key for the deadsnakes PPA
# See https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
ARG DEADSNAKES_GPG_KEY=F23C5A6CF475977595C89F51BA6932366A755776

ENV DEBIAN_FRONTEND=noninteractive

# Create user and app directory
RUN set -eux \
  ; groupadd -r tox --gid=10000 \
  ; useradd --no-log-init -r -g tox -m --uid=10000 tox \
  ; mkdir /app \
  ; chown tox:tox /app

# Install common build dependencies, add deadsnakes PPA and cleanup.
# (see https://github.com/deadsnakes)
# hadolint ignore=DL3008,SC2086
RUN set -eux \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends \
      ca-certificates \
      g++ \
      gcc \
      git \
      curl \
      bzip2 \
      make \
  ; savedAptMark="$(apt-mark showmanual)" \
  \
  ; apt-get install -y --no-install-recommends \
      dirmngr \
      gnupg \
  \
  ; tmp_home="$(mktemp -d)"; export GNUPGHOME="$tmp_home" \
  ; gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$DEADSNAKES_GPG_KEY" \
  ; gpg -o /usr/share/keyrings/deadsnakes.gpg --export "$DEADSNAKES_GPG_KEY" \
  ; echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/deadsnakes.gpg] https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu jammy main" >> /etc/apt/sources.list \
  \
  ; apt-mark auto '.*' > /dev/null \
  ; apt-mark manual $savedAptMark \
  ; apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
  ; rm -rf /var/lib/apt/lists/*

# Install pip3, all python versions and tox in the main python version
# hadolint ignore=DL3008,SC2086
RUN set -eux \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends python3-pip \
  ; for version in ${PYTHON_VERSIONS} ${PYTHON_MAIN_VERSION} \
    ; do \
      apt-get install -y --no-install-recommends \
        python${version} \
        python${version}-dev \
        python${version}-venv \
        python${version}-distutils \
      ; python${version} -m pip install --upgrade pip \
    ; done \
  ; python${PYTHON_MAIN_VERSION} -m pip install --no-cache tox \
  ; rm -rf /var/lib/apt/lists/*;

# Install PyPy
RUN if [ "$TARGETARCH" = "arm64" ] ; then curl -L --show-error --retry 5 -o /pypy.tar.bz2 https://downloads.python.org/pypy/pypy-${PYTHON_PYPY_VERSION}-aarch64.tar.bz2 \
  ; else curl -L --show-error --retry 5 -o /pypy.tar.bz2 https://downloads.python.org/pypy/pypy${PYTHON_PYPY_VERSION}-linux64.tar.bz2 \
  ; fi \
  ; mkdir /pypy && tar -xf /pypy.tar.bz2 -C /pypy --strip-components=1

ENV PATH="/pypy/bin:$PATH"

# Set the working directory and user
WORKDIR /app
VOLUME /app
USER tox

# Add safe.directory to git to avoid setuptools_scm "unable to detect version"
# (see https://github.com/pypa/setuptools_scm/issues/797)
# This needs to run as user tox
RUN git config --global --add safe.directory '*'