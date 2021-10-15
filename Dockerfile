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

ARG ARM_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.07/gcc-arm-none-eabi-10.3-2021.07-x86_64-linux.tar.bz2
RUN wget -nv --show-progress --progress=bar:force:noscroll ${ARM_URL} -O /opt/gcc-arm-none-eabi.tar.bz2 && \
    mkdir -p /opt/gcc-arm-none-eabi && \
    pv --force /opt/gcc-arm-none-eabi.tar.bz2 | tar xj --directory /opt/gcc-arm-none-eabi --strip-components 1
ENV PATH=/opt/gcc-arm-none-eabi/bin:${PATH}

# get user id from build arg, so we can have read/write access to directories
# mounted inside the container. only the UID is necessary, UNAME just for
# cosmetics
ARG UID=1010
ARG UNAME=builder

RUN useradd --uid $UID --create-home --user-group ${UNAME} && \
    echo "${UNAME}:${UNAME}" | chpasswd && adduser ${UNAME} sudo

USER ${UNAME}

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

ENV PATH /home/${UNAME}/.local/bin:$PATH

RUN pip3 install pre-commit==2.11.1 compiledb==0.10.1

WORKDIR /mnt/workspace
