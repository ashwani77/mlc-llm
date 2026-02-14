# Quick Reference Card

## 🚀 Getting Started

### Initial Setup
```bash
# 1. Clone or fork the MLC-LLM repository
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# 2. Copy CI/CD files to correct locations
cp /path/to/Dockerfile docker/
cp /path/to/entrypoint.sh docker/
cp /path/to/ci-cd.yml .github/workflows/
cp /path/to/.dockerignore .

# 3. Make entrypoint executable
chmod +x docker/entrypoint.sh

# 4. Set up GitHub secrets (see BEGINNERS_GUIDE.md)

# 5. Commit and push
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

---

## 🐳 Docker Commands

### Building
```bash
# Build the image
docker build -f docker/Dockerfile -t mlc-llm-builder .

# Build with no cache (fresh build)
docker build --no-cache -f docker/Dockerfile -t mlc-llm-builder .
```

### Running - Development Mode
```bash
# Start interactive shell
docker run -it --rm mlc-llm-builder

# Mount local directory
docker run -it --rm -v $(pwd):/workspace mlc-llm-builder

# With GPU support (NVIDIA)
docker run -it --rm --gpus all mlc-llm-builder
```

### Running - Build Mode
```bash
# Show help
docker run --rm mlc-llm-builder mlc_llm --help

# Build a wheel
docker run --rm \
  -v $(pwd)/dist:/output \
  mlc-llm-builder \
  bash -c "cd /workspace/mlc-llm/python && python setup.py bdist_wheel && cp dist/*.whl /output/"

# Run tests
docker run --rm mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/ -v"
```

### Managing Images
```bash
# List images
docker images | grep mlc-llm

# Remove image
docker rmi mlc-llm-builder

# Pull from GHCR
docker pull ghcr.io/USERNAME/REPO/mlc-llm-builder:latest

# Clean up unused images
docker image prune -a
```

---

## 📦 GitHub Container Registry (GHCR)

### Authentication
```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Using a PAT
echo $PAT_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

### Pulling Images
```bash
# Pull latest
docker pull ghcr.io/USERNAME/REPO/mlc-llm-builder:latest

# Pull specific tag
docker pull ghcr.io/USERNAME/REPO/mlc-llm-builder:main-abc123

# List all tags (requires authenticated gh CLI)
gh api \
  -H "Accept: application/vnd.github+json" \
  /users/USERNAME/packages/container/mlc-llm-builder/versions
```

### Making Image Public
1. Go to package page: `https://github.com/users/USERNAME/packages/container/package/PACKAGE_NAME`
2. Click "Package settings"
3. Scroll to "Danger Zone"
4. Click "Change visibility" → "Public"

---

## 🔧 GitHub Actions

### Workflow Management
```bash
# Trigger workflow manually (requires gh CLI)
gh workflow run ci-cd.yml

# List workflow runs
gh run list --workflow=ci-cd.yml

# View specific run
gh run view RUN_ID

# Watch a run in real-time
gh run watch RUN_ID

# Download artifacts
gh run download RUN_ID
```

### Workflow Triggers
```yaml
# On push to main
on:
  push:
    branches: [ main ]

# On pull request
on:
  pull_request:
    branches: [ main ]

# Manual trigger
on:
  workflow_dispatch:

# On tags
on:
  push:
    tags:
      - 'v*'

# Scheduled (cron)
on:
  schedule:
    - cron: '0 0 * * 0'  # Every Sunday at midnight
```

---

## 🧪 Testing

### Local Testing
```bash
# Run all tests
docker run --rm mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/"

# Run specific test file
docker run --rm mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/test_file.py"

# Run with verbose output
docker run --rm mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/ -v"

# Run with coverage
docker run --rm mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/ --cov=mlc_llm"
```

### Validating Workflow
```bash
# Install actionlint
# macOS: brew install actionlint
# Linux: see TESTING_TROUBLESHOOTING.md

# Validate workflow syntax
actionlint .github/workflows/ci-cd.yml

# Check for common issues
actionlint -verbose .github/workflows/ci-cd.yml
```

---

## 📥 Installing Built Wheels

### From GitHub Releases
```bash
# Download from browser or:
wget https://github.com/USERNAME/REPO/releases/download/TAG/mlc_llm-VERSION-PLATFORM.whl

# Install
pip install mlc_llm-VERSION-PLATFORM.whl

# Or install directly from URL
pip install https://github.com/USERNAME/REPO/releases/download/TAG/mlc_llm-VERSION-PLATFORM.whl
```

### Platform-Specific
```bash
# Linux
pip install mlc_llm-*-linux_x86_64.whl

# Windows
pip install mlc_llm-*-win_amd64.whl

# In virtual environment
python -m venv mlc-env
source mlc-env/bin/activate  # Linux/Mac
# or
mlc-env\Scripts\activate  # Windows
pip install mlc_llm-*.whl
```

---

## 🔑 Environment Variables

### Docker Build
```bash
# Set during build
docker build --build-arg PYTHON_VERSION=3.11 -f docker/Dockerfile -t mlc-llm-builder .

# In Dockerfile
ARG PYTHON_VERSION=3.11
```

### Docker Run
```bash
# Pass environment variable
docker run -e MLC_LLM_HOME=/custom/path mlc-llm-builder

# Pass multiple variables
docker run \
  -e VAR1=value1 \
  -e VAR2=value2 \
  mlc-llm-builder
```

### GitHub Actions
```yaml
# Set environment variable for entire workflow
env:
  CUSTOM_VAR: value

# Set for specific job
jobs:
  build:
    env:
      JOB_VAR: value

# Set for specific step
steps:
  - name: Step
    env:
      STEP_VAR: value
```

---

## 🛠️ Common Tasks

### Update Dependencies
```dockerfile
# In Dockerfile, modify:
RUN pip install --no-cache-dir \
    numpy==1.24.0 \
    torch==2.0.0 \
    transformers==4.30.0
```

### Change Python Version
```dockerfile
# In Dockerfile
FROM python:3.11-slim
# or
RUN apt-get install -y python3.11
```

### Add New Platform
```yaml
# In ci-cd.yml, add new job:
build-macos-wheel:
  runs-on: macos-latest
  steps:
    - uses: actions/checkout@v4
    # ... similar to Windows build
```

### Customize Build
```bash
# In Docker container
cd /workspace/mlc-llm
mkdir build && cd build
python ../cmake/gen_cmake_config.py

# Edit config.cmake
vim config.cmake

# Build
cmake .. && make -j$(nproc)
```

---

## 🐛 Debugging

### View Container Internals
```bash
# Start container with shell
docker run -it --rm --entrypoint bash mlc-llm-builder

# Inside container, explore:
ls /workspace/mlc-llm
python -c "import mlc_llm; print(mlc_llm.__file__)"
which mlc_llm
```

### Check Logs
```bash
# GitHub Actions logs
gh run view RUN_ID --log

# Docker build logs
docker build --progress=plain -f docker/Dockerfile . 2>&1 | tee build.log

# Container logs
docker logs CONTAINER_ID
```

### Interactive Debugging
```bash
# Override entrypoint for debugging
docker run -it --rm --entrypoint /bin/bash mlc-llm-builder

# Run with debug output
docker run --rm mlc-llm-builder bash -x -c "your-command"
```

---

## 📊 Monitoring

### Check Status
```bash
# Workflow status
gh run list --workflow=ci-cd.yml --limit 10

# Image layers
docker history mlc-llm-builder:latest

# Image size
docker images mlc-llm-builder --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### Performance
```bash
# Build time per layer
docker build --progress=plain -f docker/Dockerfile . 2>&1 | grep "DONE"

# Workflow job durations
gh run view RUN_ID --json jobs --jq '.jobs[] | {name, conclusion, duration: (.completedAt | fromdateiso8601) - (.startedAt | fromdateiso8601)}'
```

---

## 🔗 Useful Links

- **GitHub Actions**: https://docs.github.com/en/actions
- **Docker Docs**: https://docs.docker.com/
- **GHCR Docs**: https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry
- **MLC-LLM Docs**: https://llm.mlc.ai/docs/
- **Your Actions**: `https://github.com/USERNAME/REPO/actions`
- **Your Packages**: `https://github.com/USERNAME?tab=packages`

---

## 💾 Quick Save

```bash
# Save this reference for quick access
curl -o quick-ref.md https://raw.githubusercontent.com/USERNAME/REPO/main/QUICK_REFERENCE.md
```

---

**Pro Tip**: Keep this file handy and add your own frequently-used commands!
