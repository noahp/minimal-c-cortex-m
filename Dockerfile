FROM ubuntu:hirsute

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install --no-install-recommends \
    build-essential \
    cppcheck \
    clang-12 \
    clang-format-12 \
    clang-tidy-12 \
    git \
    jq \
    lld-12 \
    llvm-12 \
    pv \
    python3-pip \
    wget \
    && rm -rf /var/lib/apt/lists/*

ARG ARM_URL=https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.07/gcc-arm-none-eabi-10.3-2021.07-x86_64-linux.tar.bz2
ARG ARM_SHA256=8c5b8de344e23cd035ca2b53bbf2075c58131ad61223cae48510641d3e556cea
RUN wget -nv --show-progress --progress=bar:force:noscroll ${ARM_URL} -O /opt/gcc-arm-none-eabi.tar.bz2 && \
    echo "${ARM_SHA256}  /opt/gcc-arm-none-eabi.tar.bz2" | sha256sum --check && \
    mkdir -p /opt/gcc-arm-none-eabi && \
    pv --force /opt/gcc-arm-none-eabi.tar.bz2 | tar xj --directory /opt/gcc-arm-none-eabi --strip-components 1 && \
    rm /opt/gcc-arm-none-eabi.tar.bz2
ENV PATH=/opt/gcc-arm-none-eabi/bin:${PATH}

RUN ln -s clang-format-12 /usr/bin/clang-format
RUN ln -s clang-tidy-12 /usr/bin/clang-tidy

# get user id from build arg, so we can have read/write access to directories
# mounted inside the container. only the UID is necessary, UNAME just for
# cosmetics
ARG UID=1010
ARG UNAME=builder

RUN useradd --uid $UID --create-home --user-group ${UNAME} && \
    echo "${UNAME}:${UNAME}" | chpasswd

USER ${UNAME}

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

ENV PATH /home/${UNAME}/.local/bin:$PATH

RUN pip3 install pre-commit==2.11.1 compiledb==0.10.1

WORKDIR /mnt/workspace
