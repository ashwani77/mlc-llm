# MLC-LLM CI/CD Pipeline

This project sets up a production CI/CD pipeline for MLC-LLM that builds Python wheels for Linux and Windows. The pipeline runs on GitHub Actions and publishes to GitHub Container Registry and GitHub Releases.

## Quick Start

If you just want to get this running:

1. Add the workflow files to `.github/workflows/`
2. Enable GitHub Actions in your fork's settings
3. Push to main and watch it build

First runs are slower, but subsequent builds are much faster thanks to caching.

## What You Need

**GitHub Side:**
- A GitHub account (obviously)
- The mlc-ai/mlc-llm repo (forked or cloned)
- GitHub Actions enabled
- Container registry access (it's free for public repos)

The `GITHUB_TOKEN` is provided automatically - you don't need to set it up manually.

## Dependencies

### Linux Build (runs in Docker)

The Docker build uses Ubuntu 22.04 as the base and installs:

**Compilers and build tools:**
- GCC/G++ 11+
- CMake 3.24+
- Clang 17 (via LLVM)

**Languages:**
- Python 3.11
- Rust (latest stable)

**Python packages:**
```python
numpy>=1.24.0
torch>=2.0.0
transformers>=4.30.0
pytest>=7.4.0
mlc-ai-nightly-cpu  # Pre-built TVM
```

The TVM package comes pre-built, which saves us from a very long build process.

### Windows Build (native, no Docker)

Windows builds run natively on GitHub's Windows runners with Visual Studio 2022. We install the same Python packages, but we skip LLVM because Chocolatey's LLVM doesn't include `llvm-config.exe`, which we need. Building LLVM from source takes forever, so we just build CPU-only on Windows.

This is fine - users can still use GPU features if they have CUDA installed when they run the wheel.

### Submodules

MLC-LLM uses git submodules for some dependencies:
- `3rdparty/tvm/` - The TVM compiler
- `3rdparty/tokenizers-cpp/` - Tokenization library
- `3rdparty/xgrammar/` - Grammar parsing

Make sure you clone with `--recursive` or run:
```bash
git submodule update --init --recursive
```

## Building Stuff

### Docker Image

Building the Docker image is straightforward:

```bash
docker build -f docker/Dockerfile -t mlc-llm-builder .
```

This process includes several steps:

1. **Base setup** - Install Ubuntu packages, set up Python
2. **Install build tools** - Rust, LLVM, CMake
3. **Clone MLC-LLM** - Gets the source code with all submodules
4. **Install Python deps** - NumPy, PyTorch, etc.
5. **Build MLC-LLM** - Run CMake and make (this is the slow part)
6. **Install package** - `pip install -e .`
7. **Test** - Make sure everything works

The CMake config is set to:
- Use LLVM ✓
- Enable logging ✓
- No CUDA (CPU only)
- No Metal (macOS only)
- No Vulkan
- No OpenCL
- No ROCm

### Using the Docker Image

The image works in two modes:

**Development mode** (when you don't pass any arguments):
```bash
docker run -it mlc-llm-builder
# Drops you into a bash shell
```

This is handy for poking around, running tests manually, or debugging.

**Build mode** (when you pass a command):
```bash
docker run mlc-llm-builder pytest tests/
# Runs the command and exits
```

This is what the CI/CD pipeline uses.

The entrypoint script detects which mode to use based on whether you passed arguments. Pretty simple:

```bash
#!/bin/bash
if [ $# -eq 0 ]; then
    exec /bin/bash  # No args? Interactive!
else
    exec "$@"       # Args? Run them!
fi
```

### Building Wheels

#### Linux

```bash
# Build the Docker image first if you haven't
docker build -f docker/Dockerfile -t mlc-llm-builder .

# Build the wheel
mkdir -p dist
docker run --rm -v $(pwd)/dist:/output mlc-llm-builder \
  bash -c "cd /workspace/mlc-llm/python && \
           python setup.py bdist_wheel && \
           cp dist/*.whl /output/"

# Check the output
ls dist/
# mlc_llm-0.1.0-py3-none-linux_x86_64.whl
```

#### Windows

Windows is a bit different since we build natively:

```powershell
# Clone the repo
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# Install dependencies
pip install numpy torch transformers pytest packaging
pip install --pre -U -f https://mlc.ai/wheels mlc-ai-nightly-cpu

# Configure the build
mkdir build
cd build

# Create a config file (CPU-only because no llvm-config on Windows)
@"
set(CMAKE_BUILD_TYPE RelWithDebInfo)
set(USE_LLVM OFF)
set(USE_CUDA OFF)
set(USE_METAL OFF)
set(USE_VULKAN OFF)
"@ | Out-File config.cmake -Encoding ASCII

# Build it
cmake -G "Visual Studio 17 2022" -A x64 -DUSE_LLVM=OFF ..
cmake --build . --config Release --parallel 4

# Build the wheel
cd ..\python
python setup.py bdist_wheel

# Done!
dir dist\
# mlc_llm-0.1.0-py3-none-win_amd64.whl
```

The CPU-only build is intentional - Chocolatey's LLVM is incomplete, and we're not spending resources building LLVM from scratch just for slightly better codegen.

### Installing Wheels

Once you've got a wheel:

```bash
pip install dist/mlc_llm-*.whl
mlc_llm --help
python -c "import mlc_llm; print(mlc_llm.__version__)"
```

## GitHub Actions Workflow

The workflow is in `.github/workflows/ci-cd.yml` and has 5 jobs:

```
docker-build  →  test  →  build-linux
                          build-windows  →  publish
```

### Triggers

The workflow runs on:
- **Push to main** - Full pipeline including release
- **Pull requests** - Build and test only (no release)
- **Manual trigger** - Via the Actions tab or `gh workflow run`

### Job 1: docker-build

This job builds the Docker image and pushes it to GitHub Container Registry.

**What it does:**
1. Checks out the code (with submodules)
2. Sets up Docker Buildx (for better caching)
3. Logs into GHCR using the auto-provided `GITHUB_TOKEN`
4. Builds the image with caching enabled
5. Pushes it to `ghcr.io/YOUR_USERNAME/mlc-llm/mlc-llm-builder`

**Tags:**
- `latest` (only on main branch)
- `sha-abc123` (always includes commit hash)

**Caching:**
The build uses Docker layer caching stored in GHCR. This significantly speeds up subsequent builds. First builds take longer, cached builds are much faster.

### Job 2: test

This is the quality gate - if tests fail here, nothing else runs.

**What it does:**
1. Pulls the Docker image that was just built
2. Runs pytest inside the container
3. Verifies imports work (`import mlc_llm, tvm`)

The pytest step allows failures because some tests need a GPU. But the import test is strict - if that fails, the pipeline stops.

### Job 3: build-linux

Builds the Linux wheel inside Docker.

**What it does:**
1. Runs the Docker container with a volume mount
2. Builds the wheel with `python setup.py bdist_wheel`
3. Copies it to the host
4. Uploads as a GitHub Actions artifact

### Job 4: build-windows

Builds the Windows wheel natively (no Docker).

**What it does:**
1. Clones the MLC-LLM repo
2. Installs Python 3.11 and dependencies
3. Installs Rust
4. Builds with CMake (CPU-only, `USE_LLVM=OFF`)
5. Builds the wheel
6. Uploads as artifact

**Why no LLVM?**

Windows Chocolatey's LLVM package doesn't include `llvm-config.exe`, which the TVM build scripts need. We could build LLVM from source, but that would significantly increase build time. The CPU-only build works fine and is much more efficient.

### Job 5: publish

Only runs on pushes to main (not on PRs).

**What it does:**
1. Downloads both wheel artifacts
2. Creates a GitHub Release with tag `build-N`
3. Attaches the wheels to the release
4. Generates release notes with install instructions

## Publishing

### GitHub Container Registry

Your Docker image gets pushed to:
```
ghcr.io/YOUR_USERNAME/YOUR_REPO/mlc-llm-builder:latest
```

You can pull and use it:
```bash
docker pull ghcr.io/YOUR_USERNAME/YOUR_REPO/mlc-llm-builder:latest
docker run -it ghcr.io/YOUR_USERNAME/YOUR_REPO/mlc-llm-builder:latest
```

### GitHub Releases

Releases are created at:
```
https://github.com/YOUR_USERNAME/YOUR_REPO/releases
```

Each release has:
- A tag like `build-42`
- Both wheel files attached
- Installation instructions
- The commit SHA

Download them:
```bash
# Via browser - just click the assets

# Via CLI
gh release download build-42

# Via curl
curl -LO https://github.com/USER/REPO/releases/download/build-42/mlc_llm-*.whl
```

## What's Next

Once the pipeline is running, you can:
- Customize the build config (enable CUDA, etc.)
- Add notifications for failed builds
- Create additional platform builds (macOS, ARM)

The structure is pretty flexible, so adapt it to your needs.