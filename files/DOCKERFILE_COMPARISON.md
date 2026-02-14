# Dockerfile Options - Which One Should You Use?

## 🎯 Quick Decision Guide

**Answer these questions:**

1. **Do you need GPU/CUDA support?**
   - YES → Use `Dockerfile-cuda-fixed`
   - NO → Continue to question 2

2. **Do you need to build from source?**
   - YES → Use `Dockerfile-cpu-optimized`
   - NO → Use `Dockerfile-simple` (fastest!)

3. **For CI/CD (building wheels)?**
   - Use `Dockerfile-cpu-optimized` or `Dockerfile-simple`

---

## 📊 Detailed Comparison

| Feature | Simple | CPU-Optimized | CUDA-Fixed | Your Original |
|---------|--------|---------------|------------|---------------|
| **Build Time** | 5-10 min | 20-30 min | 30-40 min | 30-40 min |
| **Image Size** | ~2 GB | ~4 GB | ~8 GB | ~8 GB |
| **RAM Needed** | 2-4 GB | 4-6 GB | 6-8 GB | 8+ GB |
| **CUDA Support** | ❌ | ❌ | ✅ | ✅ |
| **Builds from Source** | ❌ | ✅ | ✅ | ✅ |
| **Parallel Build Jobs** | N/A | 4 | 4 | All cores |
| **Interactive Prompts** | None | Fixed | Fixed | Broken |
| **Reliability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

---

## 🔍 Detailed Breakdown

### Option 1: Dockerfile-simple ⭐ RECOMMENDED FOR CI/CD

**What it does:**
- Uses pre-built MLC-LLM packages from nightly builds
- No source compilation needed
- Fastest and most reliable

**Pros:**
- ✅ Fastest build time (5-10 minutes)
- ✅ Smallest image size
- ✅ Most reliable (no compilation issues)
- ✅ Works with minimal RAM
- ✅ Perfect for CI/CD pipelines

**Cons:**
- ❌ No CUDA/GPU support
- ❌ Uses nightly builds (not absolute latest code)
- ❌ Can't customize build configuration

**Best for:**
- CI/CD pipelines
- Quick testing
- Building Python wheels
- Users who don't need GPU support
- Users who want fastest setup

**Build command:**
```bash
docker build -f Dockerfile-simple -t mlc-llm-builder .
```

---

### Option 2: Dockerfile-cpu-optimized ⭐ RECOMMENDED FOR SOURCE BUILDS

**What it does:**
- Builds MLC-LLM from source
- CPU-only configuration
- Fixed interactive prompt issues
- Limited parallel jobs (prevents OOM)

**Pros:**
- ✅ Builds from latest source code
- ✅ No interactive prompt issues
- ✅ Reliable compilation
- ✅ Detailed error messages
- ✅ Works with moderate RAM (4-6GB)

**Cons:**
- ❌ Slower build time (20-30 minutes)
- ❌ No CUDA/GPU support
- ❌ Larger image size

**Best for:**
- Developers who need latest source
- CI/CD when you need source builds
- CPU-only deployments
- Building custom configurations

**Build command:**
```bash
docker build -f Dockerfile-cpu-optimized -t mlc-llm-builder .
```

---

### Option 3: Dockerfile-cuda-fixed ⭐ RECOMMENDED FOR GPU USERS

**What it does:**
- Builds from source with CUDA 12.1 support
- Fixed interactive prompts
- Limited parallel jobs
- Full GPU acceleration

**Pros:**
- ✅ CUDA/GPU support
- ✅ Builds from source
- ✅ No interactive prompt issues
- ✅ FlashAttention support
- ✅ cuBLAS, cuDNN enabled

**Cons:**
- ❌ Slowest build time (30-40 minutes)
- ❌ Largest image size (~8GB)
- ❌ Requires 6-8GB RAM
- ❌ Needs NVIDIA GPU to run

**Best for:**
- GPU development
- Training/inference with CUDA
- Maximum performance
- Users with NVIDIA GPUs

**Build command:**
```bash
docker build -f Dockerfile-cuda-fixed -t mlc-llm-builder .
```

---

## 🔧 What Was Fixed in Your Dockerfile?

Your original Dockerfile had these issues:

### Issue 1: Interactive Prompts ❌
**Your version:**
```dockerfile
echo "\ny\ny\ny\nn\nn\nn\nn" | python ../cmake/gen_cmake_config.py
```

**Problem:** The echo command doesn't reliably feed answers to interactive prompts

**Fixed version:**
```dockerfile
# Create config.cmake file directly
cat > config.cmake << 'EOF'
set(USE_CUDA ON)
set(USE_LLVM "/usr/lib/llvm-17/bin/llvm-config")
# ... more settings
EOF
cmake ..
```

**Why it works:** No interactive prompts at all - config is pre-written

---

### Issue 2: Memory Exhaustion ❌
**Your version:**
```dockerfile
make -j$(nproc)
```

**Problem:** Uses ALL CPU cores, exhausts memory during parallel compilation

**Fixed version:**
```dockerfile
make -j4 VERBOSE=1
```

**Why it works:** 
- Limited to 4 parallel jobs
- VERBOSE=1 shows actual errors (not just "Error 2")

---

### Issue 3: Hidden Errors ❌
**Your version:**
```dockerfile
make -j$(nproc)
```

**Problem:** When build fails, you only see "Error 2", not the actual error

**Fixed version:**
```dockerfile
make -j4 VERBOSE=1 || {
    echo "====================================";
    echo "BUILD FAILED - Error details above";
    echo "====================================";
    exit 1;
}
```

**Why it works:** VERBOSE=1 shows full compiler commands and errors

---

### Issue 4: Missing Dependencies
**Your version:**
- Only installs `mlc-ai-nightly-cpu`

**Fixed version:**
- Installs additional Python packages:
  ```dockerfile
  attrs decorator psutil typing_extensions
  ```
- Correctly installs `mlc-ai-nightly-cu121` for CUDA version

---

## 🎯 Recommendations by Use Case

### For CI/CD Pipelines (Wheel Building)
```
Primary: Dockerfile-simple
Backup: Dockerfile-cpu-optimized
```

**Why:** Fast builds save money and time on CI/CD runners

---

### For Development (Without GPU)
```
Primary: Dockerfile-cpu-optimized
Backup: Dockerfile-simple
```

**Why:** Access to latest source code for development

---

### For Development (With GPU)
```
Primary: Dockerfile-cuda-fixed
Only option for GPU support
```

**Why:** Need CUDA for GPU-accelerated inference/training

---

### For Production Deployment
```
CPU: Dockerfile-simple
GPU: Dockerfile-cuda-fixed
```

**Why:** Reliability and stability are most important

---

## 🚀 Quick Start Commands

### Test Simple Version (Fastest)
```bash
cd /path/to/your/repo
cp Dockerfile-simple docker/Dockerfile
docker build -f docker/Dockerfile -t mlc-llm-builder .
docker run --rm mlc-llm-builder mlc_llm --help
```

### Test CPU-Optimized (From Source)
```bash
cd /path/to/your/repo
cp Dockerfile-cpu-optimized docker/Dockerfile
docker build -f docker/Dockerfile -t mlc-llm-builder .
docker run --rm mlc-llm-builder mlc_llm --help
```

### Test CUDA-Fixed (GPU Support)
```bash
cd /path/to/your/repo
cp Dockerfile-cuda-fixed docker/Dockerfile
docker build -f docker/Dockerfile -t mlc-llm-builder .
docker run --rm --gpus all mlc-llm-builder mlc_llm --help
```

---

## 🧪 How to Verify Success

After building, run these tests:

```bash
# 1. Check import works
docker run --rm mlc-llm-builder python -c "import mlc_llm; print('✓ Import OK')"

# 2. Check CLI works
docker run --rm mlc-llm-builder mlc_llm --help

# 3. Check version
docker run --rm mlc-llm-builder python -c "import mlc_llm; print('Version:', mlc_llm.__version__)"

# 4. Test wheel building
docker run --rm -v $(pwd)/dist:/output mlc-llm-builder \
  bash -c "cd /workspace/mlc-llm/python && python setup.py bdist_wheel && cp dist/*.whl /output/"
```

All should succeed without errors.

---

## 💡 Pro Tips

### 1. Speed Up Repeated Builds
Use Docker BuildKit cache:
```bash
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile -t mlc-llm-builder .
```

### 2. Monitor Memory Usage
```bash
docker stats
# Watch memory during build - should stay under 6-8GB
```

### 3. Save Build Logs
```bash
docker build -f docker/Dockerfile -t mlc-llm-builder . 2>&1 | tee build.log
```

### 4. Multi-Stage Build (Advanced)
For even smaller images, you can use multi-stage builds:
```dockerfile
# Build stage
FROM ubuntu:22.04 as builder
# ... build everything ...

# Runtime stage
FROM ubuntu:22.04
COPY --from=builder /workspace/mlc-llm /workspace/mlc-llm
# ... only copy what's needed ...
```

---

## 📝 Summary

**For most users and CI/CD:**
→ Use **Dockerfile-simple**

**For developers needing latest source:**
→ Use **Dockerfile-cpu-optimized**

**For GPU development:**
→ Use **Dockerfile-cuda-fixed**

**Your original Dockerfile issues:**
→ All fixed in the provided versions

---

## ✅ Migration Checklist

- [ ] Choose the right Dockerfile for your needs
- [ ] Copy it to `docker/Dockerfile`
- [ ] Test build locally
- [ ] Verify with test commands above
- [ ] Update CI/CD workflow (if needed)
- [ ] Push to GitHub
- [ ] Monitor first automated build
- [ ] Celebrate! 🎉

---

Need help deciding? Start with **Dockerfile-simple** - you can always switch later!
