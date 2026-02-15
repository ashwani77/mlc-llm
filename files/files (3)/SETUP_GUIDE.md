# MLC-LLM CI/CD Pipeline - Setup Guide

## 🚀 Quick Start (10 Minutes)

This guide will help you set up the complete CI/CD pipeline for MLC-LLM in your GitHub repository.

---

## Step 1: Prepare Your Repository

### Option A: Fork the MLC-LLM Repository

```bash
# 1. Fork https://github.com/mlc-ai/mlc-llm on GitHub
# 2. Clone your fork
git clone --recursive https://github.com/YOUR_USERNAME/mlc-llm.git
cd mlc-llm
```

### Option B: Add to Existing Repository

```bash
cd your-existing-mlc-llm-repo
git pull origin main
git submodule update --init --recursive
```

---

## Step 2: Add CI/CD Files

### Create Directory Structure

```bash
mkdir -p .github/workflows
mkdir -p docker
```

### Copy CI/CD Files

Copy the following files from this package to your repository:

```
your-repo/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          ← Copy here
├── docker/
│   ├── Dockerfile             ← Copy here
│   └── entrypoint.sh          ← Copy here
└── .dockerignore              ← Copy here
```

**Commands:**

```bash
# Assuming you have the CI/CD package files in ~/mlc-llm-cicd/
cp ~/mlc-llm-cicd/ci-cd.yml .github/workflows/
cp ~/mlc-llm-cicd/Dockerfile docker/
cp ~/mlc-llm-cicd/entrypoint.sh docker/
cp ~/mlc-llm-cicd/.dockerignore .
chmod +x docker/entrypoint.sh
```

---

## Step 3: Configure GitHub Settings

### Enable GitHub Actions

1. Go to your repository on GitHub
2. Click **Settings** → **Actions** → **General**
3. Under "Actions permissions", select **"Allow all actions and reusable workflows"**
4. Under "Workflow permissions", select **"Read and write permissions"**
5. Check **"Allow GitHub Actions to create and approve pull requests"**
6. Click **Save**

### Enable GitHub Container Registry (GHCR)

GHCR is automatically available - no additional setup needed!

The `GITHUB_TOKEN` is provided automatically by GitHub Actions with the necessary permissions.

---

## Step 4: Test Locally (Optional but Recommended)

### Build Docker Image Locally

```bash
# Test the build
docker build -f docker/Dockerfile -t mlc-llm-builder .
```

**Expected:** Build completes successfully in 30-45 minutes

### Test Development Mode

```bash
# Start interactive shell
docker run -it --rm mlc-llm-builder

# Inside container, verify installation
mlc_llm --help
python -c "import mlc_llm; print('Success!')"
exit
```

### Test Build Mode

```bash
# Run non-interactive command
docker run --rm mlc-llm-builder mlc_llm --help
```

**Expected:** Help message displays successfully

---

## Step 5: Commit and Push

### Add Files to Git

```bash
git add .github/workflows/ci-cd.yml
git add docker/
git add .dockerignore
```

### Commit Changes

```bash
git commit -m "Add production CI/CD pipeline for MLC-LLM

- Multi-purpose Docker image (dev + build)
- Automated testing gates
- Cross-platform wheel builds (Linux, Windows)
- GitHub Container Registry integration
- Automated releases
"
```

### Push to GitHub

```bash
git push origin main
```

---

## Step 6: Monitor First Build

### Watch the Workflow

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You should see a workflow run starting

### Expected Timeline

| Job | Duration | Status Indicator |
|-----|----------|-----------------|
| Build Docker Image | 30-45 min | 🔵 Running / ✅ Success |
| Run Tests | 2-5 min | 🔵 Running / ✅ Success |
| Build Linux Wheel | 5-10 min | 🔵 Running / ✅ Success |
| Build Windows Wheel | 15-25 min | 🔵 Running / ✅ Success |
| Publish Release | 1-2 min | 🔵 Running / ✅ Success |

**Total Time:** ~50-90 minutes for first run

**Subsequent Runs:** ~25-40 minutes (with caching)

### Check Progress

Click on the running workflow to see:
- Real-time logs
- Job status
- Artifact uploads
- Error messages (if any)

---

## Step 7: Verify Success

### Check Docker Image

1. Go to your repository → **Packages** (right sidebar)
2. You should see `mlc-llm-builder` package
3. Click on it to see tags and details

**Or via command line:**

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# Pull the image
docker pull ghcr.io/YOUR_USERNAME/mlc-llm/mlc-llm-builder:latest

# Test it
docker run --rm ghcr.io/YOUR_USERNAME/mlc-llm/mlc-llm-builder:latest mlc_llm --help
```

### Check GitHub Release

1. Go to your repository → **Releases**
2. You should see a new release: `build-1` (or latest number)
3. It should contain:
   - Linux wheel (.whl)
   - Windows wheel (.whl)
   - Installation instructions

### Download and Test Wheel

```bash
# Download from release page or:
wget https://github.com/YOUR_USERNAME/mlc-llm/releases/download/build-1/mlc_llm-*-linux_x86_64.whl

# Create test environment
python -m venv test-env
source test-env/bin/activate  # or test-env\Scripts\activate on Windows

# Install
pip install mlc_llm-*-linux_x86_64.whl

# Test
mlc_llm --help
python -c "import mlc_llm; print('Wheel installation successful!')"
```

---

## 🎉 Success Checklist

- [ ] CI/CD files added to repository
- [ ] GitHub Actions enabled with correct permissions
- [ ] Local Docker build tested (optional)
- [ ] Changes committed and pushed
- [ ] Workflow ran successfully
- [ ] Docker image available in GHCR
- [ ] GitHub Release created with wheels
- [ ] Wheel downloaded and tested

**If all checkboxes are checked: Congratulations! 🎉**

Your CI/CD pipeline is fully operational!

---

## 🔧 Customization Options

### Change Python Version

Edit `docker/Dockerfile`:

```dockerfile
# Change this line:
python3.11 \
python3.11-dev \

# To your preferred version:
python3.10 \
python3.10-dev \
```

### Add macOS Support

Edit `.github/workflows/ci-cd.yml` and add a macOS job similar to the Windows job:

```yaml
build-macos-wheel:
  name: Build macOS Wheel (x64)
  needs: run-tests
  runs-on: macos-latest
  steps:
    # Similar to Windows build steps
```

### Customize Build Configuration

Edit `docker/Dockerfile` to change CMake options:

```dockerfile
# Find this section:
RUN python ../cmake/gen_cmake_config.py << 'EOF'
y  # Use LLVM? (change to n to disable)
y  # Enable logging? (change to n to disable)
n  # Use CUDA? (change to y to enable GPU)
n  # Use Metal? (change to y on macOS)
n  # Use Vulkan?
n  # Use OpenCL?
n  # Use ROCm?
EOF
```

### Add More Tests

Edit `.github/workflows/ci-cd.yml` in the `run-tests` job:

```yaml
- name: Run custom tests
  run: |
    docker run --rm \
      ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest \
      bash -c "cd /workspace/mlc-llm && pytest tests/your-custom-tests/"
```

---

## 🆘 Troubleshooting

### Workflow Doesn't Start

**Problem:** No workflow run appears after push

**Solutions:**
1. Verify `.github/workflows/ci-cd.yml` is in the correct location
2. Check file has `.yml` extension (not `.yaml`)
3. Check workflow syntax: https://www.yamllint.com/
4. Verify GitHub Actions is enabled in Settings

### Docker Build Fails

**Problem:** Build fails during Docker image creation

**Solutions:**
1. Check error message in workflow logs
2. Run build locally to see full output:
   ```bash
   docker build --progress=plain -f docker/Dockerfile -t test . 2>&1 | tee build.log
   ```
3. Common fixes:
   - Increase Docker memory allocation (8GB minimum)
   - Check internet connection (downloads dependencies)
   - Clear Docker cache: `docker system prune -a`

### Permission Denied - GHCR

**Problem:** Cannot push to GitHub Container Registry

**Solutions:**
1. Settings → Actions → General
2. Under "Workflow permissions", select "Read and write permissions"
3. Save and re-run workflow

### Tests Fail

**Problem:** Test job shows failures

**Solutions:**
1. Check which specific test failed in logs
2. Some tests may require GPU (these are allowed to fail)
3. Focus on import tests and CLI tests - these must pass

### Windows Build Fails

**Problem:** Windows wheel build fails

**Solutions:**
1. Check LLVM installation step
2. Verify CMake is finding LLVM correctly
3. Check if submodules were properly initialized

---

## 📞 Getting Help

### Resources

1. **This Documentation:** Start here - most issues are covered
2. **GitHub Actions Logs:** Click on failed job for detailed error messages
3. **MLC-LLM Docs:** https://llm.mlc.ai/docs/
4. **GitHub Actions Docs:** https://docs.github.com/en/actions

### Support Channels

1. **GitHub Issues:** Open an issue in your repository
2. **MLC-LLM Discord:** https://discord.gg/9Xpy2HGBuD
3. **Stack Overflow:** Tag with `mlc-llm` and `github-actions`

### What to Include When Asking for Help

- Error message (full text)
- Link to failed workflow run
- Steps you've tried
- Environment details (OS, Docker version, etc.)
- Relevant configuration files

---

## 🎓 Next Steps

### After Setup

1. **Customize** the pipeline for your needs
2. **Add tests** specific to your use case
3. **Set up branch protection** to require CI checks
4. **Configure notifications** for build failures
5. **Document** any custom changes

### Advanced Topics

- **Multi-stage Docker builds** for smaller images
- **Matrix builds** for multiple Python versions
- **Conditional releases** based on semantic versioning
- **Integration with deployment platforms**

---

## 📝 Maintenance

### Regular Updates

**Weekly:**
- Check for new MLC-LLM releases
- Update base image if needed

**Monthly:**
- Review and update dependencies
- Check for GitHub Actions updates
- Review and optimize build times

**As Needed:**
- Update when MLC-LLM changes build process
- Respond to security advisories
- Add support for new platforms

### Keeping Pipeline Healthy

1. **Monitor build times** - should stay relatively consistent
2. **Check artifact sizes** - sudden increases may indicate issues
3. **Review test coverage** - add tests for new features
4. **Update documentation** - keep README current

---

**Congratulations on setting up your CI/CD pipeline!** 🚀

You now have a production-ready, automated build system for MLC-LLM.
