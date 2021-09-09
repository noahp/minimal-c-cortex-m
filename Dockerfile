# Image where the tests run
FROM ubuntu:focal

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install \
    build-essential \
    cppcheck \
    clang-11 \
    clang-format \
    clang-tidy-11 \
    git \
    jq \
    lld-11 \
    llvm-11 \
    pv \
    python3-pip \
    wget

# GCC-ARM compiler
ARG ARM_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2020q2/gcc-arm-none-eabi-9-2020-q2-update-x86_64-linux.tar.bz2?revision=05382cca-1721-44e1-ae19-1e7c3dc96118&la=en&hash=D7C9D18FCA2DD9F894FD9F3C3DC9228498FA281A
RUN wget -nv --show-progress --progress=bar:force:noscroll ${ARM_URL} -O /opt/gcc-arm-none-eabi.tar.bz2 && \
    mkdir -p /opt/gcc-arm-none-eabi && \
    pv --force /opt/gcc-arm-none-eabi.tar.bz2 | tar xj --directory /opt/gcc-arm-none-eabi --strip-components 1
ENV PATH=/opt/gcc-arm-none-eabi/bin:${PATH}

## Build CodeChecker
ARG CC_VERSION=3ea0f3b20ef000e2841c04545b6d01809570dbed
RUN apt-get update && apt-get -y install \
    build-essential \
    curl \
    gcc-multilib \
    git \
    python3-dev \
    python3-venv \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get install -y nodejs

# Download CodeChecker release.
# Build CodeChecker. hack installing wheel, it's busted without.
RUN git clone --depth 1 https://github.com/Ericsson/CodeChecker.git /codechecker \
    && cd /codechecker \
    && git checkout ${CC_VERSION} \
    && ACTIVATE_RUNTIME_VENV=". venv/bin/activate && pip install wheel==0.34.2" make venv \
    && . venv/bin/activate && BUILD_LOGGER_64_BIT_ONLY=YES make package

# CodeChecker needs these to be exact :(
RUN \
    ln -s clang-tidy-11 /usr/bin/clang-tidy \
    && ln -s clang-11 /usr/bin/clang

# get user id from build arg, so we can have read/write access to directories
# mounted inside the container. only the UID is necessary, UNAME just for
# cosmetics
ARG UID=1010
ARG UNAME=builder

RUN useradd --uid $UID --create-home --user-group ${UNAME} && \
    echo "${UNAME}:${UNAME}" | chpasswd && adduser ${UNAME} sudo

USER ${UNAME}

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

ENV PATH /home/${UNAME}/.local/bin:/codechecker/build/CodeChecker/bin:$PATH

RUN pip3 install pre-commit==2.11.1 compiledb==0.10.1

# these are for CodeChecker
RUN pip3 install \
    alembic==1.5.5 \
    gitpython==3.1.11 \
    lxml==4.6.3 \
    mypy_extensions==0.4.3 \
    portalocker==2.2.1 \
    psutil==5.8.0 \
    PyYAML==5.4.1 \
    sqlalchemy==1.3.23 \
    thrift==0.13.0

WORKDIR /mnt/workspace
