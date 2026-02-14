# Multi-purpose Docker image for MLC-LLM
# Can be used for both development (interactive) and building (CI/CD)

# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up timezone
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    cmake \
    git \
    wget \
    curl \
    ninja-build \
    # Python
    python3 \
    python3-pip \
    python3-dev \
    # Libraries
    libssl-dev \
    libffi-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev \
    # Tools
    vim \
    nano \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Create symbolic link for python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Upgrade pip
RUN python -m pip install --upgrade pip setuptools wheel

# Install Rust (required for Hugging Face tokenizers)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install LLVM 17 (required for TVM)
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gpg-agent \
    && wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 17 \
    && rm llvm.sh \
    && rm -rf /var/lib/apt/lists/*

# Set LLVM environment variables
ENV LLVM_CONFIG=/usr/bin/llvm-config-17

# Create working directory
WORKDIR /workspace

# Clone MLC-LLM repository
RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git /workspace/mlc-llm

# Set MLC-LLM source directory
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm

# Install Python dependencies
WORKDIR /workspace/mlc-llm
RUN pip install --no-cache-dir \
    numpy \
    torch \
    transformers \
    pytest \
    pytest-cov

# Install TVM (MLC-LLM dependency)
RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# Build MLC-LLM from source
RUN mkdir -p build && cd build \
    && python ../cmake/gen_cmake_config.py \
    && cmake .. \
    && make -j$(nproc) \
    && cd ..

# Install MLC-LLM Python package
WORKDIR /workspace/mlc-llm/python
RUN pip install -e .

# Verify installation
RUN mlc_llm --help || python -m mlc_llm --help

# Set working directory back to workspace
WORKDIR /workspace

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# Default command (will be passed to entrypoint)
CMD []

# Labels for the image
LABEL org.opencontainers.image.source=https://github.com/mlc-ai/mlc-llm
LABEL org.opencontainers.image.description="Multi-purpose MLC-LLM builder and development environment"
LABEL org.opencontainers.image.licenses=Apache-2.0
