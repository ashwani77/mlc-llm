# 1. Base stage with all dependencies from Option 2
FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 AS base

# Install system-level dependencies (CMake >= 3.24, Git, etc.)
RUN apt-get update && apt-get install -y \
    git build-essential cmake python3 python3-dev python3-pip \
    libcurl4-openssl-dev libssl-dev sudo \
    llvm-15-dev  # Required for TVM backend

# Install Rust & Cargo (Required for Hugging Face tokenizers)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /workspace

# 2. Build TVM (3rdparty requirement for MLC-LLM)
# We pre-build this in the image to save CI time
RUN git clone --recursive https://github.com/mlc-ai/mlc-llm.git && \
    cd mlc-llm/3rdparty/tvm && \
    mkdir build && cd build && \
    cp ../cmake/config.cmake . && \
    echo "set(USE_CUDA ON)" >> config.cmake && \
    echo "set(USE_LLVM ON)" >> config.cmake && \
    cmake .. && make -j$(nproc)

# --- Development Stage (Interactive) ---
FROM base AS dev
RUN pip3 install pytest black mypy
ENV PYTHONPATH="/workspace/mlc-llm/python:/workspace/mlc-llm/3rdparty/tvm/python"
CMD ["/bin/bash"]

# --- Build/CI Stage (Non-interactive) ---
FROM base AS build
# Script to run the actual Option 2 build steps
COPY ci/build_from_source.sh /usr/local/bin/build_from_source
RUN chmod +x /usr/local/bin/build_from_source
ENTRYPOINT ["build_from_source"]