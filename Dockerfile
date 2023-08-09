FROM ubuntu:22.04

# List of python versions to install, space separated
# The first version will be the default (used by tox)
ARG PYTHON_VERSIONS="3.11 pypy3.9 3.7 3.8 3.9 3.10"

ENV PYENV_ROOT /root/.pyenv
ENV DEBIAN_FRONTEND noninteractive

# Install dependencies required for building python
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    make \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    liblzma-dev \
    wget \
    curl \
    llvm \
    libncurses5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    git \
    ca-certificates \
    libffi-dev \
  && apt-get clean autoclean \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/* \
  && rm -f /var/cache/apt/archives/*.deb

# Install python versions using pyenv
RUN git clone https://github.com/pyenv/pyenv $PYENV_ROOT

# hadolint ignore=SC2086
RUN for version in ${PYTHON_VERSIONS}; do \
  set -ex \
    && /root/.pyenv/bin/pyenv install ${version} \
    && /root/.pyenv/versions/${version}*/bin/python -m pip install --upgrade pip \
  ; done
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN pyenv global $(pyenv versions --bare)

# Setup commandline tools (using the first python version in the list)
RUN pip install --no-cache-dir tox

CMD ["python"]
