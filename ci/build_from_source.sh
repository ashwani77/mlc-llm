#!/bin/bash
set -e

cd /workspace/mlc-llm
mkdir -p build && cd build

# Step: Generate build configuration (python ../cmake/gen_cmake_config.py)
python3 ../cmake/gen_cmake_config.py

# Step: Build MLC LLM libraries
cmake .. && make -j $(nproc)

# Step: Install Python Package
cd ../python
pip3 install .

echo "Build complete. libmlc_llm.so and libtvm_runtime.so generated."