# MLC-LLM CI/CD Pipeline - Complete Beginner's Guide

## 📚 What You're Building

You're creating an **automated build system** for the MLC-LLM project. Think of it like a robot factory that:
1. Tests your code every time you make changes
2. Builds special packages (called "wheels") that work on different computers
3. Automatically publishes everything so others can use it

## 🎯 Key Concepts (Simple Explanations)

### What is CI/CD?
- **CI (Continuous Integration)**: Automatically test your code when you make changes
- **CD (Continuous Deployment)**: Automatically build and publish your software

### What is Docker?
A Docker image is like a pre-packaged computer environment. It contains:
- The operating system
- All the tools you need
- All the dependencies
- Your code

Think of it like a shipping container that works the same way everywhere.

### What is GitHub Actions?
It's GitHub's automation system. You write a recipe (called a "workflow"), and GitHub follows it automatically whenever certain events happen (like pushing code).

### What are Python Wheels?
Wheels (.whl files) are pre-built Python packages. Instead of users compiling from source (which is slow and error-prone), they can download and install your pre-built wheel in seconds.

## 📋 What You're Delivering

### 1. Multipurpose Docker Image
- **One image, two purposes**:
  - **Development mode**: You can open a shell and work interactively
  - **Build mode**: Runs automatically to compile the project
- **Automatically pushed** to GitHub Container Registry (GHCR)

### 2. Automated Tests
- Tests run first before building anything
- If tests fail, the build stops (this prevents broken code from being published)

### 3. Cross-Platform Builds
- Builds Python wheels for:
  - **Linux (x64)**: Most servers and many desktops
  - **Windows (x64)**: Most Windows PCs
- Publishes to GitHub Releases so anyone can download them

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│                   (Your Code Lives Here)                     │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ Push/PR Trigger
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│                  GitHub Actions Workflow                     │
│              (Automation Robot Activates)                    │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┬─────────────────┐
        │                     │                  │
        ▼                     ▼                  ▼
   Build Docker          Run Tests          Build Wheels
      Image                                (Linux/Windows)
        │                     │                  │
        │                     │                  │
        ▼                     ▼                  ▼
  Push to GHCR      ✅ Pass: Continue      Publish to
 (Container Reg)    ❌ Fail: Stop Here    GitHub Releases
```

## 📁 File Structure You'll Create

```
your-repo/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # Main automation recipe
├── docker/
│   ├── Dockerfile             # Instructions to build Docker image
│   └── entrypoint.sh          # Script that runs inside container
└── .dockerignore              # Files to ignore when building image
```

## 🔧 How Each Component Works

### 1. Dockerfile (The Recipe for Your Container)

**Purpose**: Tells Docker how to build your image

**What it does**:
1. Starts with Ubuntu (a Linux operating system)
2. Installs all dependencies (Python, build tools, etc.)
3. Clones the MLC-LLM code
4. Sets up the environment
5. Defines how the container starts

**Key sections**:
- `FROM`: What base image to start with
- `RUN`: Commands to run during build
- `COPY`: Copy files into the image
- `ENTRYPOINT`: What runs when container starts

### 2. GitHub Actions Workflow (ci-cd.yml)

**Purpose**: The automation recipe that GitHub follows

**Workflow stages**:

#### Stage 1: Build Docker Image
```
Trigger: Push to main or pull request
↓
Build the Docker image
↓
Push to GHCR (ghcr.io/your-username/mlc-llm-builder)
```

#### Stage 2: Run Tests
```
Wait for Stage 1 to complete
↓
Pull the Docker image we just built
↓
Run tests inside container
↓
If tests fail: STOP HERE ❌
If tests pass: Continue ✅
```

#### Stage 3: Build Linux Wheel
```
Wait for Stage 2 to complete
↓
Pull the Docker image
↓
Run build command inside container
↓
Extract the wheel file
↓
Save as artifact for next stage
```

#### Stage 4: Build Windows Wheel
```
Run on Windows machine (not using Docker)
Wait for Stage 2 to complete
↓
Install dependencies on Windows
↓
Build Windows wheel
↓
Save as artifact for next stage
```

#### Stage 5: Publish Release
```
Wait for Stages 3 & 4 to complete
↓
Collect all wheel files
↓
Create GitHub Release
↓
Upload wheels to release
```

### 3. Entrypoint Script

**Purpose**: Makes the Docker image multi-purpose

**How it works**:
```bash
if [ $# -eq 0 ]; then
    # No arguments = development mode
    Start an interactive bash shell
else
    # Arguments provided = build mode
    Run the command you provided
fi
```

**Examples**:
```bash
# Development mode (interactive shell)
docker run -it mlc-llm-builder

# Build mode (non-interactive)
docker run mlc-llm-builder python setup.py bdist_wheel
```

## 🚀 Step-by-Step Setup

### Step 1: Prepare Your Repository

1. Fork or clone the MLC-LLM repository
2. Create the necessary directories:
   ```bash
   mkdir -p .github/workflows
   mkdir -p docker
   ```

### Step 2: Add the Files

Copy the provided files to your repository:
- `Dockerfile` → `docker/Dockerfile`
- `entrypoint.sh` → `docker/entrypoint.sh`
- `ci-cd.yml` → `.github/workflows/ci-cd.yml`
- `.dockerignore` → `.dockerignore`

### Step 3: Configure GitHub Secrets

You need to give GitHub Actions permission to push to GHCR:

1. Go to your GitHub repo
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add a secret named `GHCR_TOKEN`:
   - Generate a Personal Access Token (PAT) with `write:packages` permission
   - Paste it as the secret value

### Step 4: Enable GitHub Actions

1. Go to **Settings** → **Actions** → **General**
2. Under "Workflow permissions", select "Read and write permissions"
3. Save

### Step 5: Trigger the Workflow

Push your changes to the main branch or create a pull request. The workflow will automatically start!

## 🔍 Monitoring Your Pipeline

### Where to Watch
- Go to your repo → **Actions** tab
- You'll see all workflow runs

### Understanding the Display
- ✅ Green checkmark = Success
- ❌ Red X = Failure
- 🟡 Yellow circle = Running
- ⚪ Gray circle = Pending

### Debugging Failures
1. Click on the failed workflow
2. Click on the failed job (e.g., "test")
3. Expand the step that failed
4. Read the error messages

## 📦 Using Your Built Artifacts

### Docker Image
```bash
# Pull your image
docker pull ghcr.io/your-username/mlc-llm-builder:latest

# Development mode
docker run -it -v $(pwd):/workspace ghcr.io/your-username/mlc-llm-builder

# Build mode
docker run ghcr.io/your-username/mlc-llm-builder python setup.py bdist_wheel
```

### Python Wheels
1. Go to your repo → **Releases**
2. Find the latest release
3. Download the wheel for your platform
4. Install with: `pip install mlc_llm-*.whl`

## 🎓 Advanced Topics (After You're Comfortable)

### Customizing the Build
- Edit `docker/Dockerfile` to change dependencies
- Edit `.github/workflows/ci-cd.yml` to add more platforms
- Add more test stages

### Adding macOS Support
You can add a macOS build job similar to Windows, but macOS runners cost more on GitHub Actions.

### Caching
Add caching to speed up builds:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
```

### Matrix Builds
Build for multiple Python versions:
```yaml
strategy:
  matrix:
    python-version: [3.9, 3.10, 3.11]
```

## ❓ Common Issues & Solutions

### Issue: "Permission denied" when pushing to GHCR
**Solution**: Check that your GHCR_TOKEN has the right permissions

### Issue: Tests fail
**Solution**: 
1. Check test output in Actions tab
2. Run tests locally with Docker first
3. Fix issues before pushing

### Issue: Windows build fails
**Solution**: Windows builds often need different dependency installation commands

### Issue: Build takes too long
**Solution**:
- Use smaller base images
- Add caching
- Build only on main branch, not on every PR

## 🎯 Success Checklist

- [ ] Docker image builds successfully
- [ ] Docker image pushed to GHCR
- [ ] Tests run and pass
- [ ] Linux wheel builds
- [ ] Windows wheel builds
- [ ] Wheels published to GitHub Releases
- [ ] You can install and use the wheel

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [Python Packaging Guide](https://packaging.python.org/)
- [MLC-LLM Documentation](https://llm.mlc.ai/docs/)

## 💡 Key Takeaways

1. **Automation saves time**: Instead of manually building for each platform, GitHub does it for you
2. **Testing prevents bugs**: Automated tests catch problems before they reach users
3. **Docker ensures consistency**: Same environment everywhere
4. **GitHub Actions is powerful**: You can automate almost anything
5. **Start simple**: Begin with basic workflow, add complexity gradually

---

**Next Steps**: 
1. Review the provided files in detail
2. Set up your repository
3. Run your first build
4. Iterate and improve

Good luck! 🚀
