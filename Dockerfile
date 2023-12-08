FROM ubuntu:22.04

## Main python version to install + use for tox
ARG PYTHON_MAIN_VERSION=3.11
## Other python versions to install
# Must be available either in the deadsnakes PPA or in
# the official Ubuntu repositories
ARG PYTHON_OTHER_VERSIONS="3.7 3.8 3.9 3.10 3.12"
## PyPy version to install
# for versions see https://www.pypy.org/download.html
ARG PYTHON_PYPY_VERSION=3.9-v7.3.12
## GPG key for the deadsnakes PPA
# See https://launchpad.net/~deadsnakes/+archive/ubuntu/ppa
ARG DEADSNAKES_GPG_KEY=F23C5A6CF475977595C89F51BA6932366A755776

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

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
      sudo \
      libpq-dev \
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
  ; for version in ${PYTHON_OTHER_VERSIONS} ${PYTHON_MAIN_VERSION} \
    ; do \
      apt-get install -y --no-install-recommends \
        python${version} \
        python${version}-dev \
        python${version}-venv \
        python${version}-distutils \
      ; python${version} -m pip install --upgrade pip || python${version} -m ensurepip --upgrade \
    ; done \
  ; python${PYTHON_MAIN_VERSION} -m pip install --no-cache tox \
  ; rm -rf /var/lib/apt/lists/*;

# Install PyPy
RUN set -eux \
  ; if [ "$TARGETARCH" = "arm64" ] ; then curl -L --show-error --retry 5 -o /pypy.tar.bz2 https://downloads.python.org/pypy/pypy${PYTHON_PYPY_VERSION}-aarch64.tar.bz2 \
  ; else curl -L --show-error --retry 5 -o /pypy.tar.bz2 https://downloads.python.org/pypy/pypy${PYTHON_PYPY_VERSION}-linux64.tar.bz2 \
  ; fi \
  ; mkdir /pypy && tar -xf /pypy.tar.bz2 -C /pypy --strip-components=1

# Make pypi available and ensure executables installed by pip are available
# (pip uses the "User Scheme" in recent Debian/Ubuntu,
# see https://packaging.python.org/en/latest/guides/installing-using-linux-tools/#debian-ubuntu)
ENV PATH="$PATH:/pypy/bin:/home/tox/.local/bin"

# Create user (with sudo privileges) and app directory
RUN set -eux \
  ; groupadd -r tox --gid=1000 \
  ; useradd --no-log-init -r -g tox -m --uid=1000 tox \
  ; adduser tox sudo \
  ; echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
  ; touch /home/tox/.sudo_as_admin_successful \
  ; mkdir /app \
  ; chown tox:tox /app

WORKDIR /app
VOLUME /app
USER tox

# Add safe.directory to git to avoid setuptools_scm "unable to detect version"
# This can't be limited to /app since gitlab-ci mounts the workspace somewhere else
# (see https://github.com/pypa/setuptools_scm/issues/797)
# This needs to run as user tox
RUN git config --global --add safe.directory '*'
