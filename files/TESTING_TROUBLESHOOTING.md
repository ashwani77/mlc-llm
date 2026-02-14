# Testing & Troubleshooting Guide

## 🧪 Local Testing (Before Pushing to GitHub)

### Test 1: Docker Build
Test the Docker image builds correctly:

```bash
cd /path/to/your/repo
docker build -f docker/Dockerfile -t mlc-llm-builder:test .
```

**Expected outcome**: Build completes successfully (may take 15-30 minutes first time)

**Common issues**:
- **Out of disk space**: Docker images can be large. Free up space or increase Docker disk allocation
- **Network errors**: Some downloads may fail. Retry the build
- **Permission denied**: Run with `sudo` or add your user to docker group

---

### Test 2: Development Mode
Test the Docker image in development mode:

```bash
docker run -it --rm mlc-llm-builder:test
```

**Expected outcome**: You get an interactive bash shell with MLC-LLM installed

**Commands to try inside**:
```bash
# Check MLC-LLM installation
mlc_llm --help

# Navigate to source
cd /workspace/mlc-llm

# Run tests
pytest tests/ -v
```

**To exit**: Type `exit` or press `Ctrl+D`

---

### Test 3: Build Mode
Test the Docker image in build mode:

```bash
# Test help command
docker run --rm mlc-llm-builder:test mlc_llm --help

# Test Python import
docker run --rm mlc-llm-builder:test python -c "import mlc_llm; print('Success!')"

# Test building a wheel
docker run --rm \
  -v $(pwd)/dist:/output \
  mlc-llm-builder:test \
  bash -c "cd /workspace/mlc-llm/python && python setup.py bdist_wheel && cp dist/*.whl /output/"
```

**Expected outcome**: Commands execute successfully, wheel appears in `./dist/`

---

### Test 4: Workflow Syntax
Validate the GitHub Actions workflow file:

```bash
# Install actionlint (workflow linter)
# macOS
brew install actionlint

# Linux
wget https://github.com/rhysd/actionlint/releases/latest/download/actionlint_linux_amd64 -O actionlint
chmod +x actionlint
sudo mv actionlint /usr/local/bin/

# Run the linter
actionlint .github/workflows/ci-cd.yml
```

**Expected outcome**: No errors reported

---

## 🚀 Testing on GitHub

### Step 1: Initial Push

```bash
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

### Step 2: Monitor Workflow

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You should see a workflow run starting

### Step 3: Understand the Workflow Progress

The workflow runs in stages:

```
Stage 1: build-docker (10-30 min)
    ↓
Stage 2: test (2-5 min)
    ├─→ Stage 3: build-linux-wheel (5-10 min)
    └─→ Stage 4: build-windows-wheel (10-15 min)
            ↓
Stage 5: publish-release (1-2 min)
```

**Total time**: 30-60 minutes for first run

### Step 4: Check Each Job

Click on each job to see its logs:

**build-docker**:
- Look for "Image built with digest"
- Check GHCR push succeeded

**test**:
- Look for "Tests completed successfully"
- If tests fail, read pytest output

**build-linux-wheel** and **build-windows-wheel**:
- Look for wheel files being created
- Check artifacts are uploaded

**publish-release**:
- Verify release is created
- Check wheels are attached

---

## 🔍 Troubleshooting Guide

### Problem: "Permission denied" when pushing to GHCR

**Symptoms**:
```
Error: denied: permission_denied: write_package
```

**Solution**:
1. Verify GHCR_TOKEN secret is set correctly
2. Check token has `write:packages` scope
3. Ensure workflow has `packages: write` permission

**How to verify**:
- Go to Settings → Secrets and variables → Actions
- GHCR_TOKEN should be listed
- Click "Update" to regenerate if needed

---

### Problem: Docker build times out

**Symptoms**:
```
Error: buildx failed with: ERROR: failed to solve: process "/bin/sh -c ..." 
did not complete successfully: context canceled
```

**Solution**:
1. GitHub Actions has 6-hour timeout - build should complete well before
2. Check if external resources (apt, pip) are slow
3. Add caching to workflow (see Advanced section in guide)

**Workaround**:
Split the Dockerfile into stages to cache intermediate layers

---

### Problem: Tests fail

**Symptoms**:
```
FAILED tests/test_something.py::test_function
```

**Solution**:
1. Check which specific test failed
2. Review test output in Actions log
3. Reproduce locally:
   ```bash
   docker run --rm mlc-llm-builder:test bash -c "cd /workspace/mlc-llm && pytest tests/test_something.py -v"
   ```
4. Fix the issue
5. Commit and push again

---

### Problem: Windows build fails

**Symptoms**:
```
Error: cmake not found
Error: MSVC required
```

**Solution**:
Windows builds are more complex. Common issues:

1. **Missing CMake**:
   - Already handled in workflow with `cmake` pip package
   
2. **MSVC/Build tools**:
   - GitHub Windows runners have Visual Studio pre-installed
   - If error persists, add explicit setup:
   ```yaml
   - name: Setup MSVC
     uses: microsoft/setup-msbuild@v1
   ```

3. **LLVM not found**:
   - May need to install LLVM on Windows
   - Add to workflow:
   ```yaml
   - name: Install LLVM
     run: choco install llvm
   ```

---

### Problem: Wheel doesn't work after installation

**Symptoms**:
```
$ pip install mlc_llm-*.whl
$ mlc_llm --help
Error: No module named 'mlc_llm'
```

**Solution**:
1. Check wheel was built for correct platform
2. Verify Python version matches (3.9, 3.10, 3.11)
3. Check wheel contents:
   ```bash
   unzip -l mlc_llm-*.whl
   ```
4. Try installing in fresh virtual environment:
   ```bash
   python -m venv test_env
   source test_env/bin/activate  # or test_env\Scripts\activate on Windows
   pip install mlc_llm-*.whl
   ```

---

### Problem: Release not created

**Symptoms**:
- Workflow completes but no release appears

**Solution**:
1. Check if workflow was triggered by push to main
   - Releases only happen on main branch
2. Verify `publish-release` job ran
3. Check job has `contents: write` permission
4. Review release creation step logs

---

### Problem: Can't pull Docker image

**Symptoms**:
```
Error: manifest unknown
Error: unauthorized
```

**Solution**:
1. Image is private by default. Make it public:
   - Go to package settings on GitHub
   - Change visibility to public

2. Or authenticate:
   ```bash
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

---

## 📊 Monitoring & Logs

### View Detailed Logs

1. Go to Actions → Click on workflow run
2. Click on specific job
3. Expand any step to see full output
4. Download logs with "Download log archive" button

### Check Docker Image

```bash
# Pull the image
docker pull ghcr.io/your-username/mlc-llm-builder:latest

# Inspect it
docker inspect ghcr.io/your-username/mlc-llm-builder:latest

# Check size
docker images | grep mlc-llm-builder
```

### Verify Wheel Installation

```bash
# Download wheel from release
wget https://github.com/your-username/mlc-llm/releases/download/build-1/mlc_llm-*.whl

# Create test environment
python -m venv test-wheel
source test-wheel/bin/activate

# Install and test
pip install mlc_llm-*.whl
mlc_llm --help
```

---

## 🎯 Validation Checklist

Use this checklist to verify everything works:

- [ ] Docker image builds locally
- [ ] Can run container in development mode
- [ ] Can run container in build mode
- [ ] Workflow file passes syntax check
- [ ] Workflow runs on GitHub
- [ ] Docker image pushed to GHCR
- [ ] Tests pass
- [ ] Linux wheel builds successfully
- [ ] Windows wheel builds successfully
- [ ] Release created with both wheels
- [ ] Can download and install Linux wheel
- [ ] Can download and install Windows wheel
- [ ] Installed package works correctly

---

## 💡 Tips

### Speed Up Testing

1. **Test locally first**: Always test Docker builds and workflow syntax locally

2. **Use draft releases**: Change `draft: true` in workflow during testing

3. **Limit workflow triggers**: During development, trigger manually:
   ```yaml
   on:
     workflow_dispatch:  # Manual trigger only
   ```

4. **Test on branches**: Create a test branch to avoid cluttering main

### Debugging Docker Builds

```bash
# Build and tag each stage
docker build --target builder -t mlc-llm:builder .

# Run intermediate stage
docker run -it mlc-llm:builder bash

# Check specific layer
docker history mlc-llm-builder:test
```

### Reading GitHub Actions Logs

- **Green checkmark**: Step succeeded
- **Red X**: Step failed (click to expand)
- **Yellow**: Step was skipped
- **Duration**: Shows how long each step took
- **Annotations**: Warnings and errors are highlighted

---

## 🆘 Getting Help

If you're stuck:

1. **Check workflow logs** in GitHub Actions
2. **Review this troubleshooting guide**
3. **Test locally** with Docker
4. **Search GitHub Issues** in MLC-LLM repo
5. **Ask for help** with:
   - Full error message
   - Workflow run link
   - Steps you've tried

Remember: CI/CD pipelines have many moving parts. It's normal to encounter issues. Methodically work through them one at a time.
