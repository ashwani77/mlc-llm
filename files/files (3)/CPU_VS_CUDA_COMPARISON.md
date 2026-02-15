# CPU vs CUDA Dockerfile Comparison

## Current Situation

You have **two Dockerfile options**:

### 1. Dockerfile (CPU-Only) - Currently Provided ✅
- **Base Image:** `ubuntu:22.04`
- **CUDA:** No
- **Build Configuration:** CPU-only
- **Use Case:** CI/CD, wheel building, CPU deployments

### 2. Dockerfile-with-cuda (NEW) - CUDA Enabled 🆕
- **Base Image:** `nvidia/cuda:12.1.1-devel-ubuntu22.04`
- **CUDA:** Yes (12.1 + cuDNN)
- **Build Configuration:** CUDA + cuBLAS enabled
- **Use Case:** GPU development, GPU inference

---

## Key Differences

| Feature | CPU Dockerfile | CUDA Dockerfile |
|---------|---------------|-----------------|
| **Base Image** | ubuntu:22.04 | nvidia/cuda:12.1.1-devel |
| **Size** | ~4 GB | ~8 GB |
| **Build Time** | 30-40 min | 40-60 min |
| **CUDA Support** | ❌ | ✅ |
| **cuDNN** | ❌ | ✅ (libcudnn8) |
| **cuBLAS** | ❌ | ✅ |
| **TVM Package** | mlc-ai-nightly-cpu | mlc-ai-nightly-cu121 |
| **Needs GPU** | No | Yes (for runtime) |
| **CI/CD Ready** | ✅ | ⚠️ (needs GPU runners) |

---

## Build Configuration Comparison

### CPU Dockerfile
```dockerfile
RUN python ../cmake/gen_cmake_config.py << 'EOF'
y  # Use LLVM?
y  # Enable logging?
n  # Use CUDA? ← NO
n  # Use Metal?
n  # Use Vulkan?
n  # Use OpenCL?
n  # Use ROCm?
EOF
```

### CUDA Dockerfile
```dockerfile
RUN python ../cmake/gen_cmake_config.py << 'EOF'
y  # Use LLVM?
y  # Enable logging?
y  # Use CUDA? ← YES
n  # Use Metal?
n  # Use Vulkan?
n  # Use OpenCL?
n  # Use ROCm?
EOF
```

---

## Which One Should You Use?

### Use CPU Dockerfile When:

✅ **Building Python wheels for distribution**
- Wheels work on both CPU and GPU machines
- Faster builds
- No GPU needed for CI/CD

✅ **CI/CD pipeline**
- GitHub Actions standard runners don't have GPUs
- Cheaper and faster
- Reliable builds

✅ **CPU-only deployments**
- Servers without GPUs
- Development machines without GPUs

### Use CUDA Dockerfile When:

✅ **GPU development**
- Testing GPU features
- GPU-accelerated inference
- Training or fine-tuning

✅ **Maximum performance**
- Need cuBLAS optimizations
- Need CUDA kernels
- Production GPU deployments

✅ **Local development with GPU**
- Have NVIDIA GPU available
- Want to test GPU code paths

---

## Important Facts About Wheel Building

### The Built Wheels Are The Same!

**Key Insight:** Whether you build a wheel in a CPU or CUDA container, the resulting `.whl` file:
- ✅ Works on both CPU and GPU machines
- ✅ Detects CUDA at runtime (if available)
- ✅ Falls back to CPU if no GPU

**Example:**
```bash
# Build in CPU container
docker run cpu-builder python setup.py bdist_wheel
# Output: mlc_llm-0.1.0.whl

# Build in CUDA container
docker run cuda-builder python setup.py bdist_wheel
# Output: mlc_llm-0.1.0.whl

# Both wheels are functionally identical!
# GPU support is determined at RUNTIME, not build time
```

---

## For Your CI/CD Pipeline

### Recommendation: Use CPU Dockerfile ⭐

**Why?**

1. **GitHub Actions doesn't have GPU runners** (on free tier)
2. **Faster builds** = Less CI/CD cost
3. **More reliable** = Fewer build failures
4. **Wheels work on GPU anyway** = Users get GPU support

### Workflow:

```
CI/CD (CPU build)
    ↓
Build wheels
    ↓
Publish to releases
    ↓
Users download
    ↓
Users with GPU → GPU acceleration ✅
Users without GPU → CPU inference ✅
```

---

## For Development

### Recommendation: Use CUDA Dockerfile if you have GPU

**Workflow:**

```bash
# Pull CUDA-enabled image
docker pull your-image:cuda

# Run with GPU access
docker run -it --gpus all your-image:cuda

# Inside container
python
>>> import torch
>>> torch.cuda.is_available()
True  # ✅ GPU detected
```

---

## Switching Between Versions

### Option 1: Use Both (Recommended)

**CPU for CI/CD:**
```yaml
# .github/workflows/ci-cd.yml
- name: Build Docker image
  uses: docker/build-push-action@v5
  with:
    file: ./docker/Dockerfile  # CPU version
```

**CUDA for local development:**
```bash
# Local development
docker build -f Dockerfile-with-cuda -t mlc-llm-cuda .
docker run -it --gpus all mlc-llm-cuda
```

### Option 2: Replace Current Dockerfile

```bash
# Use CUDA version everywhere
mv Dockerfile Dockerfile.cpu
mv Dockerfile-with-cuda Dockerfile
```

**⚠️ Warning:** CUDA builds may fail in standard GitHub Actions runners (no GPU)

---

## Testing Both Versions

### Test CPU Version
```bash
docker build -f Dockerfile -t mlc-llm-cpu .
docker run --rm mlc-llm-cpu python -c "import torch; print('CUDA:', torch.cuda.is_available())"
# Output: CUDA: False ✅ (expected)
```

### Test CUDA Version
```bash
docker build -f Dockerfile-with-cuda -t mlc-llm-cuda .
docker run --rm --gpus all mlc-llm-cuda python -c "import torch; print('CUDA:', torch.cuda.is_available())"
# Output: CUDA: True ✅ (if GPU available)
```

---

## GitHub Actions Implications

### If You Use CUDA Dockerfile in CI/CD:

**Problems:**
- ❌ Longer build times (40-60 min vs 30-40 min)
- ❌ Larger images (8GB vs 4GB)
- ❌ Can't test GPU features (no GPU on runners)
- ❌ Higher chance of build failures (more dependencies)

**Benefits:**
- ✅ Wheels built in CUDA environment (though this doesn't matter)

### If You Use CPU Dockerfile in CI/CD:

**Benefits:**
- ✅ Faster builds
- ✅ Smaller images
- ✅ More reliable
- ✅ Cheaper CI/CD costs
- ✅ Wheels still work on GPU machines

**Drawbacks:**
- ⚠️ Can't test GPU features in CI (would need GPU runners)

---

## My Recommendation

### For Your Use Case (CI/CD Pipeline):

**Use the CPU Dockerfile** (the one I provided in the complete package)

**Why?**
1. Your goal is to build and distribute wheels
2. The wheels work identically on CPU and GPU machines
3. Faster, cheaper, more reliable CI/CD
4. You can still use CUDA locally for development

### For Local GPU Development:

**Use the CUDA Dockerfile** (Dockerfile-with-cuda)

```bash
# Keep both files:
docker/
├── Dockerfile           # CPU (for CI/CD)
└── Dockerfile.cuda      # CUDA (for local dev)

# CI/CD uses Dockerfile
# You use Dockerfile.cuda locally
```

---

## Quick Decision Matrix

| Scenario | Use This Dockerfile |
|----------|-------------------|
| CI/CD wheel building | CPU ⭐ |
| No GPU available | CPU |
| CPU-only deployment | CPU |
| Have NVIDIA GPU | CUDA |
| Testing GPU features | CUDA |
| Maximum performance | CUDA |
| Unsure | CPU (safer choice) |

---

## Summary

**Question:** "Is Dockerfile gonna use CUDA libraries?"

**Answer:** 
- Current Dockerfile: **No** (CPU-only)
- Dockerfile-with-cuda: **Yes** (CUDA 12.1 + cuDNN)

**Recommendation:**
- **For CI/CD:** Keep using CPU version
- **For local GPU dev:** Use CUDA version I just created

**The wheels you build work on both CPU and GPU regardless of which Dockerfile you use!**

---

Would you like me to:
1. ✅ Keep the CPU Dockerfile for CI/CD (current package)
2. 🔄 Replace with CUDA Dockerfile everywhere
3. 📦 Provide both versions with documentation
