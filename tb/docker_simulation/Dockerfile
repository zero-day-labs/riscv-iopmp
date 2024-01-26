# base image
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive

# docker image arguments
# ARG CPPCHECK_VERSION=2.9

# Install base dependencies
RUN apt-get update && apt-get install -y \
        git \
        curl \
        wget \
        xz-utils \
        apt-utils \
        build-essential \
        gcc-multilib \
        python3 \
        python3-pip \
        enchant-2 \
        software-properties-common \
        ninja-build \
        pkg-config \
        libglib2.0-dev \
        libpixman-1-dev \
        libslirp-dev \
        bison \
        flex \
        tree \
        vim \
        nano \
        device-tree-compiler

# Install python packages
RUN pip3 install \
        cocotb \
        cocotb_test \
        cocotbext-axi \
        numpy \
        pytest 

# Install verilator dependencies
RUN apt-get install -y help2man perl python3 make autoconf g++ flex bison ccache \
    libgoogle-perftools-dev numactl perl-doc \
    libfl2 libfl-dev zlib1g zlib1g-dev

RUN git clone https://github.com/verilator/verilator 
WORKDIR /verilator
RUN autoconf
RUN ./configure
RUN make -j `nproc` -j8
RUN make install -j8

RUN pip3 install \
        bitarray

RUN apt-get update && apt-get install -y \
        gtkwave

# default startup command
CMD /bin/bash
