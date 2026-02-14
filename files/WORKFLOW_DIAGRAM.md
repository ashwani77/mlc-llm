# CI/CD Pipeline Visual Workflow

## Overview Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         TRIGGER EVENT                           │
│                                                                 │
│  • Push to main branch                                         │
│  • Pull request to main                                        │
│  • Manual workflow dispatch                                    │
└────────────────────────┬───────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    JOB 1: BUILD DOCKER                          │
│                                                                 │
│  Steps:                                                        │
│  1. Checkout code                                              │
│  2. Set up Docker Buildx                                       │
│  3. Login to GHCR                                              │
│  4. Extract metadata (tags, labels)                            │
│  5. Build and push Docker image                                │
│                                                                 │
│  Duration: ~15-30 minutes (first run)                          │
│           ~5-10 minutes (cached)                               │
│                                                                 │
│  Output: ghcr.io/user/repo/mlc-llm-builder:latest             │
└────────────────────────┬───────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      JOB 2: TEST                                │
│                                                                 │
│  Depends on: build-docker ✓                                    │
│                                                                 │
│  Steps:                                                        │
│  1. Checkout code                                              │
│  2. Login to GHCR                                              │
│  3. Pull Docker image                                          │
│  4. Run tests in container (pytest)                            │
│                                                                 │
│  Duration: ~2-5 minutes                                        │
│                                                                 │
│  ❌ If tests FAIL → Pipeline STOPS                             │
│  ✅ If tests PASS → Continue to builds                         │
└────────────┬───────────────────────┬──────────────────────────┘
             │                       │
             ▼                       ▼
┌────────────────────────┐  ┌──────────────────────────┐
│  JOB 3: BUILD LINUX    │  │  JOB 4: BUILD WINDOWS    │
│                        │  │                          │
│  Depends on: test ✓    │  │  Depends on: test ✓      │
│                        │  │                          │
│  Platform:             │  │  Platform:               │
│  ubuntu-latest         │  │  windows-latest          │
│                        │  │                          │
│  Steps:                │  │  Steps:                  │
│  1. Checkout           │  │  1. Checkout             │
│  2. Login to GHCR      │  │  2. Setup Python 3.11    │
│  3. Pull Docker img    │  │  3. Install deps         │
│  4. Build wheel        │  │  4. Install Rust         │
│  5. Upload artifact    │  │  5. Configure build      │
│                        │  │  6. Build MLC-LLM        │
│  Duration: ~5-10 min   │  │  7. Build wheel          │
│                        │  │  8. Upload artifact      │
│  Output:               │  │                          │
│  mlc_llm-*-            │  │  Duration: ~10-15 min    │
│  linux_x86_64.whl      │  │                          │
│                        │  │  Output:                 │
│                        │  │  mlc_llm-*-              │
│                        │  │  win_amd64.whl           │
└────────────┬───────────┘  └───────────┬──────────────┘
             │                          │
             └────────────┬─────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                  JOB 5: PUBLISH RELEASE                         │
│                                                                 │
│  Depends on: build-linux-wheel ✓, build-windows-wheel ✓       │
│  Condition: Push to main only                                  │
│                                                                 │
│  Steps:                                                        │
│  1. Checkout code                                              │
│  2. Download Linux wheel artifact                              │
│  3. Download Windows wheel artifact                            │
│  4. Generate release notes                                     │
│  5. Create GitHub Release                                      │
│  6. Upload wheels to release                                   │
│                                                                 │
│  Duration: ~1-2 minutes                                        │
│                                                                 │
│  Output: GitHub Release with wheels                            │
│          Tag: build-<run_number>                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Flow

### Stage 1: Build Docker Image

```
Start
  │
  ├─► Checkout repository (with submodules)
  │
  ├─► Set up Docker Buildx (for multi-platform builds)
  │
  ├─► Login to GitHub Container Registry
  │     Input: GITHUB_TOKEN (automatic)
  │     Output: Authentication successful
  │
  ├─► Extract metadata
  │     Generates:
  │     - Tags: latest, main-sha123, pr-45
  │     - Labels: org.opencontainers.image.*
  │
  ├─► Build Docker image
  │     FROM ubuntu:22.04
  │     ├─► Install system dependencies
  │     ├─► Install Python & pip
  │     ├─► Install Rust
  │     ├─► Install LLVM 17
  │     ├─► Clone MLC-LLM
  │     ├─► Build MLC-LLM from source
  │     ├─► Install Python package
  │     └─► Copy entrypoint script
  │
  └─► Push to GHCR
        Location: ghcr.io/user/repo/mlc-llm-builder:latest
```

**Cache Strategy**: 
- Uses layer caching
- Stores cache in GHCR
- Subsequent builds reuse unchanged layers

---

### Stage 2: Run Tests

```
Start
  │
  ├─► Pull Docker image from GHCR
  │
  ├─► Run container with test command
  │     docker run mlc-llm-builder bash -c "pytest tests/"
  │
  ├─► Execute pytest
  │     Tests:
  │     ├─► Unit tests
  │     ├─► Integration tests
  │     └─► Functional tests
  │
  └─► Check exit code
        Exit 0: ✅ PASS → Continue
        Exit 1: ❌ FAIL → Stop pipeline
```

**Failure Handling**:
- If any test fails, pipeline stops
- No wheels are built or published
- Ensures only tested code is released

---

### Stage 3: Build Linux Wheel

```
Start (only if tests passed)
  │
  ├─► Pull Docker image
  │
  ├─► Create output directory
  │     mkdir -p dist/
  │
  ├─► Run build in container
  │     docker run -v ./dist:/output mlc-llm-builder
  │       cd /workspace/mlc-llm/python
  │       python setup.py bdist_wheel
  │       cp dist/*.whl /output/
  │
  ├─► Verify wheel created
  │     Check: dist/mlc_llm-*.whl exists
  │
  └─► Upload as artifact
        Name: mlc-llm-linux-x64-wheel
        Retention: 7 days
```

**Wheel Format**: `mlc_llm-VERSION-py3-none-linux_x86_64.whl`

---

### Stage 4: Build Windows Wheel

```
Start (only if tests passed)
  │
  ├─► Checkout code
  │
  ├─► Setup Python 3.11
  │
  ├─► Install build dependencies
  │     pip install wheel setuptools cmake ninja
  │     pip install mlc-ai-nightly-cpu
  │
  ├─► Install Rust toolchain
  │
  ├─► Configure MLC-LLM
  │     mkdir build && cd build
  │     python ../cmake/gen_cmake_config.py
  │     cmake ..
  │
  ├─► Build C++ libraries
  │     cmake --build . --config Release
  │
  ├─► Build Python wheel
  │     cd python
  │     python setup.py bdist_wheel
  │
  └─► Upload as artifact
        Name: mlc-llm-windows-x64-wheel
        Retention: 7 days
```

**Wheel Format**: `mlc_llm-VERSION-py3-none-win_amd64.whl`

---

### Stage 5: Publish Release

```
Start (only on push to main, after wheels built)
  │
  ├─► Download Linux wheel artifact
  │     From: mlc-llm-linux-x64-wheel
  │     To: release-artifacts/linux/
  │
  ├─► Download Windows wheel artifact
  │     From: mlc-llm-windows-x64-wheel
  │     To: release-artifacts/windows/
  │
  ├─► Generate release notes
  │     Content:
  │     ├─► Installation instructions
  │     ├─► Build information
  │     ├─► Docker image details
  │     └─► Platform support
  │
  ├─► Create GitHub Release
  │     Tag: build-<run_number>
  │     Name: "MLC-LLM Build <run_number>"
  │     Body: Generated notes
  │     Assets: Both .whl files
  │
  └─► Publish release
        Public URL: github.com/user/repo/releases/latest
```

---

## Parallel Execution

Jobs run in parallel when possible:

```
build-docker
      │
      ▼
    test
      │
      ├──────────────┬──────────────┐
      ▼              ▼              ▼
build-linux    build-windows     (other jobs)
      │              │
      └──────┬───────┘
             ▼
      publish-release
```

**Benefits**:
- Faster total pipeline time
- Efficient use of runners
- Independent platform builds

---

## Error Handling Flow

```
Any Job Fails?
      │
      ├─► Yes → Mark job as failed
      │         │
      │         ├─► Stop dependent jobs
      │         └─► Send notification
      │
      └─► No → Continue to next stage
```

**Scenarios**:

1. **Docker build fails**:
   - All subsequent jobs canceled
   - Pipeline shows red ❌

2. **Tests fail**:
   - Wheels are not built
   - Release is not published
   - Pipeline shows red ❌

3. **Linux wheel fails**:
   - Windows build continues (parallel)
   - Release waits for both
   - If Windows succeeds but Linux fails → No release

4. **Windows wheel fails**:
   - Similar to Linux failure
   - No release without both wheels

---

## Artifact Flow

```
┌──────────────┐         ┌──────────────┐
│  Docker Img  │────────▶│     GHCR     │
│  (Container) │         │  (Registry)  │
└──────────────┘         └──────────────┘
                                │
                                │ Used by
                                ▼
                         ┌──────────────┐
                         │     Test     │
                         │     Jobs     │
                         └──────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│ Linux Wheel  │────────▶│   Artifact   │────────▶│   GitHub     │
│    (.whl)    │         │   Storage    │         │   Release    │
└──────────────┘         └──────────────┘         └──────────────┘
                                │
┌──────────────┐                │
│ Win Wheel    │────────────────┘
│    (.whl)    │
└──────────────┘
```

---

## Timeline (Typical Run)

```
Time  Job                    Status
────────────────────────────────────────────
0:00  build-docker           🔵 Running
0:15  build-docker           ✅ Complete
0:15  test                   🔵 Running
0:18  test                   ✅ Complete
0:18  build-linux-wheel      🔵 Running
0:18  build-windows-wheel    🔵 Running
0:23  build-linux-wheel      ✅ Complete
0:30  build-windows-wheel    ✅ Complete
0:30  publish-release        🔵 Running
0:32  publish-release        ✅ Complete
────────────────────────────────────────────
Total Duration: ~32 minutes
```

**Note**: Times vary based on:
- Cache hits
- Runner availability
- Network speed
- Build complexity

---

## Resource Usage

### Compute Resources

```
Job                  Runner          CPU    Memory
─────────────────────────────────────────────────────
build-docker         ubuntu-latest   2      7 GB
test                 ubuntu-latest   2      7 GB
build-linux-wheel    ubuntu-latest   2      7 GB
build-windows-wheel  windows-latest  2      7 GB
publish-release      ubuntu-latest   2      7 GB
```

### Storage

```
Artifact                    Size        Retention
──────────────────────────────────────────────────
Docker image (GHCR)         ~5-8 GB     Permanent
Linux wheel (artifact)      ~100-200MB  7 days
Windows wheel (artifact)    ~100-200MB  7 days
GitHub Release wheels       ~200-400MB  Permanent
```

---

## Success Metrics

✅ **Pipeline Success** when:
1. Docker image builds and pushes
2. All tests pass
3. Both platform wheels build
4. Release created with both wheels
5. Wheels are installable and functional

❌ **Pipeline Failure** if:
1. Docker build fails
2. Any test fails
3. Either wheel build fails
4. Release creation fails
5. GitHub token/permissions issue

---

This visual workflow helps you understand the entire CI/CD process at a glance!
