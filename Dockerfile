# MLC-LLM CI/CD Docker Image
# Multi-purpose: Development environment + Build environment
# Follows official MLC-LLM "Option 2: Build from Source" instructions
# Reference: https://llm.mlc.ai/docs/install/mlc_llm.html#option-2-build-from-source

FROM ubuntu:22.04

# =============================================================================
# ENVIRONMENT SETUP
# =============================================================================

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    MLC_LLM_SOURCE_DIR=/workspace/mlc-llm

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# =============================================================================
# STEP 1: INSTALL BUILD DEPENDENCIES
# As specified in official documentation
# =============================================================================

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials (required)
    build-essential \
    cmake \
    git \
    wget \
    curl \
    # Python (required)
    python3.11 \
    python3.11-dev \
    python3-pip \
    lsb-release \
    software-properties-common \
    gnupg \
    ca-certificates \
    vim \
    nano \
    htop \
    && wget https://apt.llvm.org/llvm-snapshot.gpg.key \
    && apt-key add llvm-snapshot.gpg.key \
    && echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-17 main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y \
        llvm-17 \
        llvm-17-dev \
        llvm-17-tools \
        clang-17 \
        lld-17 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Upgrade pip
RUN python -m pip install --upgrade pip setuptools wheel

# Install Rust and Cargo (required for Hugging Face tokenizers)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
#
# # Install LLVM 17 (required for TVM)
# RUN wget https://apt.llvm.org/llvm.sh && \
#     chmod +x llvm.sh && \
#     ./llvm.sh 17 all && \
#     rm llvm.sh && \
#     rm -rf /var/lib/apt/lists/*

ENV LLVM_CONFIG=/usr/bin/llvm-config-17 \
    LLVM_HOME=/usr/lib/llvm-17 \
    PATH=/usr/lib/llvm-17/bin:${PATH}

# =============================================================================
# STEP 2: CLONE MLC-LLM REPOSITORY
# Using official git workflow
# =============================================================================

WORKDIR /workspace

RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git && \
    cd mlc-llm && \
    echo "MLC-LLM cloned at commit: $(git rev-parse HEAD)"

# =============================================================================
# STEP 3: INSTALL PYTHON DEPENDENCIES
# =============================================================================

WORKDIR /workspace/mlc-llm

# Install core dependencies for building and testing
RUN pip install --no-cache-dir \
    numpy \
    torch \
    transformers \
    attrs \
    decorator \
    psutil \
    typing_extensions \
    pytest \
    pytest-cov \
    packaging

# Install TVM (required dependency)
# Using CPU version for maximum compatibility across platforms
RUN pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# =============================================================================
# STEP 4: CONFIGURE AND BUILD MLC-LLM
# Following official build instructions
# =============================================================================

# Create build directory
RUN mkdir -p build

WORKDIR /workspace/mlc-llm/build

# Generate build configuration (CPU-only for reliability)
RUN printf "\nn\nn\nn\nn\nn\nn\nn\n" | python ../cmake/gen_cmake_config.py

# Run CMake configuration
RUN cmake .. && echo "✓ CMake configuration completed"

# Build MLC-LLM libraries (limited parallelism to avoid OOM)
RUN make -j4 && echo "✓ MLC-LLM libraries built successfully"

# Verify build outputs
RUN ls -lh libmlc_llm.so libtvm_runtime.so && echo "✓ Build artifacts verified"

# =============================================================================
# STEP 5: INSTALL MLC-LLM PYTHON PACKAGE
# Using pip editable install as recommended
# =============================================================================

WORKDIR /workspace/mlc-llm/python

RUN pip install -e . && \
    echo "✓ MLC-LLM Python package installed"

# Set PYTHONPATH now that the package is installed
#ENV PYTHONPATH=/workspace/mlc-llm/python:${PYTHONPATH}

# =============================================================================
# STEP 6: VALIDATE INSTALLATION
# =============================================================================

WORKDIR /workspace

# Verify CLI is accessible
RUN mlc_llm --help && \
    echo "✓ MLC-LLM CLI verified"

# Verify Python import
RUN python -c "import mlc_llm; print('MLC-LLM version:', mlc_llm.__version__)" && \
    echo "✓ MLC-LLM Python import verified"

# Verify build libraries are accessible
RUN python -c "import tvm; print('TVM library:', tvm.__file__)" && \
    echo "✓ TVM library verified"

# =============================================================================
# MULTI-PURPOSE ENTRYPOINT
# Enables both development and build modes
# =============================================================================

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD []

# =============================================================================
# METADATA
# =============================================================================

LABEL org.opencontainers.image.source="https://github.com/mlc-ai/mlc-llm" \
      org.opencontainers.image.description="MLC-LLM multi-purpose Docker image for development and CI/CD" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.licenses="Apache-2.0" \
      maintainer="MLC-LLM CI/CD Pipeline"