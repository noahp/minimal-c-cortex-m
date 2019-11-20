# Container suitable to build the projects

FROM ubuntu:bionic

RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi

ARG UID=1010
ARG UNAME=builder

# Configure user
RUN useradd --uid $UID --create-home --user-group ${UNAME} && \
    echo "${UNAME}:${UNAME}" | chpasswd

USER ${UNAME}
