FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential \
    libncurses-dev \
    bison \
    flex \
    libssl-dev \
    bc \
    git \
    ccache \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /kernel
