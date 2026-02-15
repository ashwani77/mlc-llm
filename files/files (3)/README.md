# MLC-LLM CI/CD Pipeline - Complete Documentation

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Dependencies](#dependencies)
4. [Building from Source](#building-from-source)
5. [Docker Environment](#docker-environment)
6. [GitHub Actions Workflow](#github-actions-workflow)
7. [Installation and Usage](#installation-and-usage)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

This project provides a **production-ready CI/CD pipeline** for MLC-LLM that:

- ✅ Follows official MLC-LLM "Option 2: Build from Source" instructions
- ✅ Provides a multi-purpose Docker image (development + build)
- ✅ Implements automated testing gates
- ✅ Builds cross-platform Python wheels (Linux x64, Windows x64)
- ✅ Publishes to GitHub Container Registry (GHCR) and GitHub Releases

**Reference Documentation:**
- Official Build Instructions: https://llm.mlc.ai/docs/install/mlc_llm.html#option-2-build-from-source
- MLC-LLM Repository: https://github.com/mlc-ai/mlc-llm

---

## 📦 Prerequisites

### For Local Development

**Required:**
- Docker (20.10+ recommended)
- Git
- 8GB+ RAM (for building from source)
- 20GB+ free disk space

**Optional:**
- Docker Compose
- NVIDIA GPU + CUDA (for GPU development)

### For CI/CD Pipeline

**Required:**
- GitHub account with repository
- GitHub Actions enabled
- GitHub Container Registry (GHCR) access

**Secrets to Configure:**
- `GITHUB_TOKEN` (automatically provided by GitHub Actions)

---

## 🔧 Dependencies

### System Dependencies

**Build Tools:**
- CMake >= 3.24
- Git
- Rust and Cargo (for tokenizers)
- LLVM >= 15 (using 17 for best compatibility)

**Runtime:**
- Python 3.11
- pip, setuptools, wheel

### Python Dependencies

**Core:**
- `mlc-ai-nightly-cpu` - TVM runtime
- `numpy` - Numerical computing
- `torch` - PyTorch
- `transformers` - Hugging Face transformers

**Development & Testing:**
- `pytest` - Testing framework
- `pytest-cov` - Code coverage
- `attrs`, `decorator`, `psutil`, `typing_extensions`

### Third-Party Components

**Included as submodules:**
- Apache TVM (3rdparty/tvm)
- xgrammar (3rdparty/xgrammar)
- tokenizers-cpp (3rdparty/tokenizers-cpp)

---

## 🏗️ Building from Source

### Option 1: Using Docker (Recommended)

#### Build the Docker Image

```bash
# Clone repository
git clone --recursive https://github.com/your-username/mlc-llm.git
cd mlc-llm

# Build Docker image
docker build -f docker/Dockerfile -t mlc-llm-builder .
```

**Build time:** ~30-45 minutes (first build), ~10-15 minutes (with cache)

#### Verify Build

```bash
# Test import
docker run --rm mlc-llm-builder python -c "import mlc_llm; print(mlc_llm.__version__)"

# Test CLI
docker run --rm mlc-llm-builder mlc_llm --help
```

### Option 2: Manual Build (Linux/macOS)

#### Step 1: Install Build Dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y build-essential cmake git wget curl python3.11 python3.11-dev

# macOS
brew install cmake git python@3.11 llvm@17
```

#### Step 2: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

#### Step 3: Install LLVM 17

```bash
# Ubuntu/Debian
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh
sudo ./llvm.sh 17

# macOS
brew install llvm@17
export LLVM_CONFIG=/usr/local/opt/llvm@17/bin/llvm-config
```

#### Step 4: Clone and Build

```bash
# Clone repository
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# Install Python dependencies
pip install --upgrade pip setuptools wheel
pip install numpy torch transformers pytest
pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# Create build directory
mkdir -p build
cd build

# Generate build configuration
python ../cmake/gen_cmake_config.py
# Answer prompts:
# - Use LLVM? y
# - Enable logging? y
# - Use CUDA? n
# - Use Metal? n (or y on macOS)
# - Use Vulkan? n
# - Use OpenCL? n
# - Use ROCm? n

# Build
cmake ..
make -j$(nproc)  # or make -j$(sysctl -n hw.ncpu) on macOS
```

#### Step 5: Install Python Package

```bash
cd ../python
pip install -e .
```

#### Step 6: Verify Installation

```bash
mlc_llm --help
python -c "import mlc_llm; print('Success!')"
```

### Option 3: Windows Build

#### Prerequisites

1. Install Visual Studio 2019 or later with C++ support
2. Install CMake (3.24+)
3. Install Python 3.11
4. Install LLVM 17: https://github.com/llvm/llvm-project/releases

#### Build Steps

```powershell
# Clone repository
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# Install Python dependencies
pip install --upgrade pip setuptools wheel
pip install numpy torch transformers pytest
pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# Install Rust
# Download from: https://www.rust-lang.org/tools/install

# Create build directory
mkdir build
cd build

# Generate build configuration
python ..\cmake\gen_cmake_config.py

# Build
cmake ..
cmake --build . --config Release -j4

# Install Python package
cd ..\python
pip install -e .
```

---

## 🐳 Docker Environment

### Multi-Purpose Design

The Docker image serves **two modes**:

#### 1. Development Mode (Interactive)

```bash
# Start interactive shell
docker run -it --rm mlc-llm-builder

# Mount local code
docker run -it --rm -v $(pwd):/workspace mlc-llm-builder

# With GPU support (if NVIDIA GPU available)
docker run -it --rm --gpus all mlc-llm-builder
```

**Inside the container:**
```bash
# Navigate to source
cd /workspace/mlc-llm

# Run tests
pytest tests/

# Build wheels
cd python
python setup.py bdist_wheel
```

#### 2. Build Mode (CI/CD)

```bash
# Run specific commands
docker run --rm mlc-llm-builder mlc_llm --help

# Build wheel
docker run --rm -v $(pwd)/dist:/output mlc-llm-builder \
  bash -c "cd /workspace/mlc-llm/python && python setup.py bdist_wheel && cp dist/*.whl /output/"

# Run tests
docker run --rm mlc-llm-builder \
  bash -c "cd /workspace/mlc-llm && pytest tests/"
```

### Image Structure

```
/workspace/mlc-llm/          # MLC-LLM source code
├── build/                   # Compiled libraries
│   ├── libmlc_llm.so
│   └── libtvm_runtime.so
├── python/                  # Python package
│   └── mlc_llm/
├── tests/                   # Test suite
└── 3rdparty/               # Dependencies (TVM, etc.)

/entrypoint.sh              # Multi-purpose entrypoint
```

### Environment Variables

| Variable | Value | Purpose |
|----------|-------|---------|
| `MLC_LLM_SOURCE_DIR` | `/workspace/mlc-llm` | Source directory |
| `PYTHONPATH` | `/workspace/mlc-llm/python:$PYTHONPATH` | Python import path |
| `LLVM_CONFIG` | `/usr/bin/llvm-config-17` | LLVM configuration |
| `PATH` | `/root/.cargo/bin:$PATH` | Include Rust binaries |

---

## ⚙️ GitHub Actions Workflow

### Workflow Structure

The CI/CD pipeline consists of **6 jobs** running in sequence with dependencies:

```
build-docker-image
      ↓
  run-tests
      ↓
  ┌───┴───┐
  ↓       ↓
linux   windows
  └───┬───┘
      ↓
publish-release
      ↓
workflow-summary
```

### Job Details

#### Job 1: Build Docker Image

**Purpose:** Build and push the multi-purpose Docker image to GHCR

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual workflow dispatch
- Release creation

**Steps:**
1. Checkout code with submodules
2. Set up Docker Buildx
3. Log in to GHCR using `GITHUB_TOKEN`
4. Extract metadata (tags, labels)
5. Build and push image with layer caching
6. Output image digest

**Outputs:**
- Docker image pushed to: `ghcr.io/{owner}/{repo}/mlc-llm-builder`
- Tags: `latest`, `{branch}`, `{sha}`, `{version}`

**Duration:** ~30-45 minutes (first build), ~10-15 minutes (cached)

---

#### Job 2: Run Tests

**Purpose:** Validate build with automated tests (gates further stages)

**Dependencies:** `build-docker-image`

**Steps:**
1. Pull the built Docker image
2. Run unit tests in container
3. Run import verification tests
4. Verify CLI functionality
5. Generate test report

**Test Categories:**
- **Unit tests:** `pytest tests/python/`
- **Import tests:** Verify `mlc_llm` and `tvm` imports
- **CLI tests:** Verify `mlc_llm --help` works

**Failure Handling:**
- Unit test failures are logged but don't block (some need GPU)
- Import and CLI failures block the pipeline

**Duration:** ~2-5 minutes

---

#### Job 3: Build Linux Wheel

**Purpose:** Build Python wheel for Linux x86_64

**Dependencies:** `run-tests` (only runs if tests pass)

**Steps:**
1. Pull Docker image
2. Run `python setup.py bdist_wheel` in container
3. Copy wheel from container to host
4. Upload as GitHub Actions artifact

**Output:**
- Artifact name: `mlc-llm-linux-x64-wheel`
- File pattern: `mlc_llm-*.whl`
- Retention: 30 days

**Duration:** ~5-10 minutes

---

#### Job 4: Build Windows Wheel

**Purpose:** Build Python wheel for Windows x86_64

**Dependencies:** `run-tests`

**Runs on:** `windows-latest` runner

**Steps:**
1. Checkout code with submodules
2. Set up Python 3.11
3. Install build dependencies (CMake, Rust, LLVM)
4. Configure build with `gen_cmake_config.py`
5. Build with CMake
6. Build wheel with `setup.py`
7. Upload as artifact

**Key Differences from Linux:**
- Uses native Windows tools (no Docker)
- Installs LLVM via Chocolatey
- Uses PowerShell and Bash commands

**Duration:** ~15-25 minutes

---

#### Job 5: Publish Release

**Purpose:** Create GitHub Release with wheels

**Dependencies:** `build-linux-wheel`, `build-windows-wheel`

**Conditions:**
- Only runs on `push` to `main` branch
- Requires `contents: write` permission

**Steps:**
1. Download Linux wheel artifact
2. Download Windows wheel artifact
3. Generate release notes with installation instructions
4. Create GitHub Release
5. Attach wheels to release

**Release Details:**
- Tag: `build-{run_number}`
- Name: `MLC-LLM Build {run_number}`
- Assets: Linux and Windows wheels
- Body: Installation instructions, build info, Docker image details

**Duration:** ~1-2 minutes

---

#### Job 6: Workflow Summary

**Purpose:** Generate comprehensive pipeline summary

**Dependencies:** All previous jobs

**Always runs:** Yes (even if previous jobs fail)

**Output:** Markdown summary in GitHub Actions UI showing:
- Status of each job
- Links to artifacts
- Links to Docker image
- Links to releases

---

### Workflow Triggers

| Trigger | Branches | Behavior |
|---------|----------|----------|
| `push` | `main`, `develop` | Full pipeline + release (main only) |
| `pull_request` | `main` | Full pipeline, no release |
| `release` | Any | Full pipeline + attach to release |
| `workflow_dispatch` | Any | Manual trigger, full pipeline |

### Publishing Behavior

**Docker Image:**
- Published on every workflow run
- Tagged with branch name, SHA, and `latest` (for main)

**GitHub Release:**
- Only published on `push` to `main` branch
- Creates new release with `build-{number}` tag
- Attaches Linux and Windows wheels

### Caching Strategy

**Docker layers:**
- Cache stored in GHCR as `buildcache` tag
- Reused across workflow runs
- Speeds up builds by 3-5x

**Dependencies:**
- Python packages cached in Docker layers
- Rust crates cached in layers
- CMake build cache not persisted (starts fresh each time)

---

## 📥 Installation and Usage

### For End Users

#### Install from GitHub Releases

```bash
# Download wheel for your platform
wget https://github.com/{owner}/{repo}/releases/download/build-123/mlc_llm-*-linux_x86_64.whl

# Install
pip install mlc_llm-*-linux_x86_64.whl
```

#### Install from Docker

```bash
# Pull image
docker pull ghcr.io/{owner}/{repo}/mlc-llm-builder:latest

# Use interactively
docker run -it ghcr.io/{owner}/{repo}/mlc-llm-builder:latest
```

### For Developers

#### Local Development

```bash
# Clone repository
git clone --recursive https://github.com/{owner}/{repo}.git
cd {repo}

# Build Docker image
docker build -f docker/Dockerfile -t mlc-llm-dev .

# Start development environment
docker run -it -v $(pwd):/workspace mlc-llm-dev
```

#### Running Tests Locally

```bash
# In Docker
docker run --rm mlc-llm-dev bash -c "cd /workspace/mlc-llm && pytest tests/"

# Or locally (if built from source)
cd mlc-llm
pytest tests/
```

#### Building Wheels Locally

```bash
# Using Docker
docker run --rm -v $(pwd)/dist:/output mlc-llm-dev \
  bash -c "cd /workspace/mlc-llm/python && python setup.py bdist_wheel && cp dist/*.whl /output/"

# Or locally
cd mlc-llm/python
python setup.py bdist_wheel
```

### Verification

After installation, verify with:

```bash
# Check version
mlc_llm --version

# Show help
mlc_llm --help

# Test import
python -c "import mlc_llm; print('MLC-LLM installed successfully!')"
```

---

## 🔍 Troubleshooting

### Common Issues

#### Docker Build Fails

**Symptom:** Docker build fails during compilation

**Solutions:**
1. **Check available memory:**
   ```bash
   docker system info | grep Memory
   ```
   Ensure at least 8GB is allocated to Docker

2. **Clear Docker cache:**
   ```bash
   docker system prune -a
   docker build --no-cache -f docker/Dockerfile -t mlc-llm-builder .
   ```

3. **Reduce parallel jobs:**
   Edit Dockerfile and change `make -j4` to `make -j2`

---

#### GitHub Actions Workflow Fails

**Symptom:** Workflow fails at specific job

**Solutions by Job:**

**build-docker-image:**
- Check GHCR permissions in repository settings
- Verify `GITHUB_TOKEN` has `packages: write` permission

**run-tests:**
- Check test logs in Actions tab
- Some tests may require GPU (these are allowed to fail)

**build-linux-wheel:**
- Verify Docker image was built successfully
- Check disk space on runner

**build-windows-wheel:**
- Verify LLVM installation step succeeds
- Check CMake configuration output

**publish-release:**
- Only runs on `main` branch
- Requires `contents: write` permission

---

#### Import Errors

**Symptom:** `ModuleNotFoundError: No module named 'mlc_llm'`

**Solutions:**
1. **Verify installation:**
   ```bash
   pip list | grep mlc
   ```

2. **Check PYTHONPATH:**
   ```bash
   echo $PYTHONPATH
   export PYTHONPATH=/workspace/mlc-llm/python:$PYTHONPATH
   ```

3. **Reinstall package:**
   ```bash
   pip uninstall mlc_llm
   pip install mlc_llm-*.whl
   ```

---

#### Build Performance Issues

**Symptom:** Build takes too long

**Solutions:**
1. **Use Docker layer caching**
2. **Reduce parallel jobs** if memory-constrained
3. **Use pre-built base images**
4. **Enable BuildKit:**
   ```bash
   DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t mlc-llm-builder .
   ```

---

### Getting Help

1. **Check documentation:** Review this README and official MLC-LLM docs
2. **Check workflow logs:** GitHub Actions → Your workflow run → Click failed job
3. **Check Docker logs:**
   ```bash
   docker logs <container_id>
   ```
4. **Open an issue:** Include:
   - Error message
   - Steps to reproduce
   - Environment details (OS, Docker version, etc.)
   - Workflow run link (if applicable)

---

## 📚 Additional Resources

### Official Documentation
- MLC-LLM Docs: https://llm.mlc.ai/docs/
- Build from Source: https://llm.mlc.ai/docs/install/mlc_llm.html#option-2-build-from-source
- TVM Documentation: https://tvm.apache.org/docs/

### GitHub Resources
- GitHub Actions: https://docs.github.com/en/actions
- GHCR: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- GitHub Releases: https://docs.github.com/en/repositories/releasing-projects-on-github

### Community
- MLC-LLM Discord: https://discord.gg/9Xpy2HGBuD
- GitHub Issues: https://github.com/mlc-ai/mlc-llm/issues
- GitHub Discussions: https://github.com/mlc-ai/mlc-llm/discussions

---

## 📄 License

This CI/CD pipeline follows the same license as MLC-LLM: **Apache 2.0**

---

**Last Updated:** 2026-02-15
**Pipeline Version:** 1.0
**MLC-LLM Version:** Latest from main branch
