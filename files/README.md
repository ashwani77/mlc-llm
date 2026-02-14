# MLC-LLM Production CI/CD Pipeline

**A beginner-friendly, production-quality CI/CD workflow for building and deploying MLC-LLM across platforms**

---

## 📦 What's Included

This package provides a **complete, production-ready CI/CD pipeline** for the MLC-LLM project with:

1. ✅ **Multi-purpose Docker Image** - Development + Build environment
2. ✅ **Automated Testing** - Test-driven deployment
3. ✅ **Cross-Platform Builds** - Linux & Windows wheels
4. ✅ **Automatic Publishing** - GitHub Releases & GHCR
5. ✅ **Beginner Documentation** - Step-by-step guides

---

## 🎯 For Complete Beginners

**Never used CI/CD before?** Start here:

1. 📖 **[BEGINNERS_GUIDE.md](BEGINNERS_GUIDE.md)** - Read this first! 
   - Explains every concept in simple terms
   - No assumed knowledge
   - Visual diagrams and examples

2. 🚀 **[setup.sh](setup.sh)** - Interactive setup script
   - Walks you through each step
   - Validates your configuration
   - Tests everything locally

3. 🧪 **[TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md)** - When things go wrong
   - Common issues and solutions
   - Step-by-step debugging
   - FAQ section

---

## 🎓 Quick Start (5 Minutes)

### Prerequisites
- GitHub account
- Git installed
- Docker installed (for local testing)

### Setup Steps

```bash
# 1. Fork/clone the MLC-LLM repository
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm

# 2. Download this CI/CD package
# (Copy all files to your repository)

# 3. Run the setup script
chmod +x setup.sh
./setup.sh

# 4. Follow the prompts to configure GitHub

# 5. Push to GitHub
git add .
git commit -m "Add CI/CD pipeline"
git push origin main

# 6. Watch the magic happen!
# Go to: https://github.com/YOUR_USERNAME/mlc-llm/actions
```

**That's it!** The pipeline will automatically:
- Build your Docker image
- Run tests
- Build wheels for Linux and Windows
- Publish everything to GitHub Releases

---

## 📚 Documentation

### Essential Reading (In Order)

| Document | Purpose | Time to Read |
|----------|---------|--------------|
| [BEGINNERS_GUIDE.md](BEGINNERS_GUIDE.md) | Understand the entire system | 30 min |
| [WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md) | Visual workflow explanation | 15 min |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Command cheat sheet | 5 min (keep handy) |
| [TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md) | Fix issues | As needed |

### Files in This Package

```
mlc-llm-cicd/
├── README.md                          # This file
├── BEGINNERS_GUIDE.md                 # Complete beginner's guide
├── WORKFLOW_DIAGRAM.md                # Visual workflow diagrams
├── QUICK_REFERENCE.md                 # Command reference card
├── TESTING_TROUBLESHOOTING.md         # Debug guide
├── setup.sh                           # Interactive setup script
├── Dockerfile                         # Docker image definition
├── entrypoint.sh                      # Multi-purpose container script
├── ci-cd.yml                          # GitHub Actions workflow
└── .dockerignore                      # Docker build exclusions
```

---

## 🏗️ Architecture Overview

### The Pipeline in 3 Sentences
1. **Docker Image**: A pre-configured environment that works everywhere
2. **Automated Tests**: Check everything works before building
3. **Cross-Platform Builds**: Create packages that work on Linux and Windows

### Visual Flow
```
Code Push → Docker Build → Tests → Build Wheels → Publish Release
              ↓                                        ↓
            GHCR                              GitHub Releases
```

See [WORKFLOW_DIAGRAM.md](WORKFLOW_DIAGRAM.md) for detailed diagrams.

---

## 🎁 What You Get

### 1. Docker Image
**Location**: `ghcr.io/YOUR_USERNAME/mlc-llm-builder`

**Use as development environment**:
```bash
docker run -it ghcr.io/YOUR_USERNAME/mlc-llm-builder
# Opens interactive shell with MLC-LLM ready to use
```

**Use as build environment**:
```bash
docker run ghcr.io/YOUR_USERNAME/mlc-llm-builder python setup.py build
# Runs commands non-interactively
```

### 2. Python Wheels
**Location**: GitHub Releases page

**Platforms**:
- Linux x86_64
- Windows x86_64

**Installation**:
```bash
pip install https://github.com/YOUR_USERNAME/mlc-llm/releases/download/TAG/mlc_llm-VERSION-PLATFORM.whl
```

### 3. Automated Tests
- Run on every commit
- Block bad code from being published
- Give you confidence in your builds

---

## 🛠️ Customization

### Change Build Settings

Edit `docker/Dockerfile`:
```dockerfile
# Change Python version
FROM ubuntu:22.04
RUN apt-get install python3.11  # Change to 3.10, 3.12, etc.

# Add more dependencies
RUN pip install your-package-here
```

### Add More Platforms

Edit `.github/workflows/ci-cd.yml`:
```yaml
# Add macOS build
build-macos-wheel:
  runs-on: macos-latest
  steps:
    # Similar to Windows build
```

### Customize Tests

Edit test command in workflow:
```yaml
- name: Run tests
  run: |
    docker run mlc-llm-builder pytest tests/ -v --your-options
```

---

## 📊 Monitoring Your Pipeline

### GitHub Actions Tab
- Green ✅ = Success
- Red ❌ = Failure  
- Yellow 🟡 = Running
- Gray ⚪ = Pending

### Check Status
```bash
# Install GitHub CLI
brew install gh  # macOS
# or download from: https://cli.github.com/

# View recent runs
gh run list --workflow=ci-cd.yml

# Watch a run
gh run watch
```

### Notifications
GitHub will email you when:
- Builds succeed
- Builds fail
- You need to take action

---

## 🔧 Common Tasks

### Build Locally
```bash
# Build the Docker image
docker build -f docker/Dockerfile -t mlc-llm-builder .

# Test it
docker run -it mlc-llm-builder
```

### Run Tests Locally
```bash
docker run mlc-llm-builder bash -c "cd /workspace/mlc-llm && pytest tests/"
```

### Manual Workflow Trigger
```bash
# Via GitHub CLI
gh workflow run ci-cd.yml

# Or via GitHub web UI:
# Actions → CI/CD Pipeline → Run workflow
```

### Download Artifacts
```bash
# List recent runs
gh run list --workflow=ci-cd.yml

# Download artifacts from a run
gh run download RUN_ID
```

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for more commands.

---

## 🐛 Troubleshooting

### Quick Fixes

**Pipeline fails immediately?**
- Check GitHub token permissions
- Verify secrets are set correctly

**Docker build times out?**
- First build takes 20-30 minutes
- Subsequent builds are much faster (caching)

**Tests fail?**
- Check test output in Actions tab
- Run tests locally to debug

**Wheels don't install?**
- Check platform matches (Linux vs Windows)
- Try in a fresh virtual environment

For detailed solutions, see [TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md).

---

## 💡 Tips for Success

1. **Start Simple**: Don't customize until basic pipeline works
2. **Test Locally**: Always test Docker builds locally first
3. **Read Logs**: GitHub Actions logs tell you exactly what failed
4. **Use Caching**: Pipeline gets faster after first run
5. **Ask for Help**: Include error messages and workflow run URLs

---

## 🎓 Learning Path

### Week 1: Get It Running
- [ ] Read BEGINNERS_GUIDE.md
- [ ] Run setup.sh
- [ ] Push to GitHub
- [ ] Watch first workflow run
- [ ] Download and test a wheel

### Week 2: Understand It
- [ ] Read WORKFLOW_DIAGRAM.md
- [ ] Build Docker image locally
- [ ] Run tests locally
- [ ] Explore the container interactively

### Week 3: Customize It
- [ ] Add a new dependency
- [ ] Modify test configuration
- [ ] Try different Python version
- [ ] Add custom build steps

### Week 4: Master It
- [ ] Add a new platform (macOS)
- [ ] Implement caching
- [ ] Add matrix builds
- [ ] Contribute improvements back

---

## 🤝 Contributing

Found a bug or have an improvement?

1. Create an issue describing the problem
2. Submit a pull request with your fix
3. Share your customizations with others

---

## 📜 License

This CI/CD pipeline is provided as-is for the MLC-LLM project.
- MLC-LLM: Apache 2.0 License
- This pipeline: Same as MLC-LLM (Apache 2.0)

---

## 🙏 Acknowledgments

Built for the MLC-LLM community with ❤️

Special thanks to:
- MLC-LLM team for the amazing project
- GitHub Actions for the platform
- Docker for containerization
- Everyone learning CI/CD

---

## 📞 Getting Help

**Need help?**
1. Check [TESTING_TROUBLESHOOTING.md](TESTING_TROUBLESHOOTING.md)
2. Review [BEGINNERS_GUIDE.md](BEGINNERS_GUIDE.md)
3. Search GitHub Issues
4. Ask in MLC-LLM Discord
5. Create a GitHub Issue with:
   - Error message
   - Workflow run link
   - Steps to reproduce

---

## ✨ Next Steps

1. ✅ **Read** [BEGINNERS_GUIDE.md](BEGINNERS_GUIDE.md)
2. ✅ **Run** `setup.sh`
3. ✅ **Push** to GitHub
4. ✅ **Monitor** your first build
5. ✅ **Download** and test wheels
6. ✅ **Celebrate** your working CI/CD pipeline! 🎉

---

**Ready to build?** Let's go! 🚀

Start with: `./setup.sh`
