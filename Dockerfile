# syntax=docker/dockerfile:1.7
FROM nvidia/cuda:12.3.0-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USER=mlc
ARG UID=1000
ARG GID=1000

# ------------------------------
# System Dependencies
# ------------------------------
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    ninja-build \
    python3.13 \
    python3.13-venv \
    python3-pip \
    llvm \
    clang \
    libtinfo-dev \
    zlib1g-dev \
    libxml2-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ------------------------------
# Install Rust (required for tokenizer)
# ------------------------------
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# ------------------------------
# Create non-root user
# ------------------------------
RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER}

WORKDIR /workspace

# ------------------------------
# Clone mlc-llm
# ------------------------------
RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git

WORKDIR /workspace/mlc-llm

# ------------------------------
# Build from source (CPU-only)
# ------------------------------
RUN mkdir -p build && cd build && \
    python3.13 ../cmake/gen_cmake_config.py && \
    cmake .. \
      -DUSE_CUDA=OFF \
      -DUSE_VULKAN=OFF \
      -DUSE_ROCM=OFF \
      -DUSE_METAL=OFF && \
    make -j$(nproc)

# ------------------------------
# Install Python package
# ------------------------------
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm
ENV PYTHONPATH=$MLC_LLM_SOURCE_DIR/python:$PYTHONPATH

# Install CLI wrapper
RUN echo 'alias mlc_llm="python3.13 -m mlc_llm"' >> /etc/bash.bashrc

USER ${USER}

ENTRYPOINT ["/bin/bash"]
