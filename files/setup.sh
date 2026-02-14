#!/bin/bash
# setup.sh - Quick setup script for MLC-LLM CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Header
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      MLC-LLM CI/CD Pipeline Setup Script                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "This doesn't appear to be a git repository."
    echo "Please run this script from the root of your MLC-LLM fork."
    exit 1
fi

print_success "Git repository detected"

# Step 1: Create directory structure
print_step "Creating directory structure..."
mkdir -p .github/workflows
mkdir -p docker
print_success "Directories created"

# Step 2: Check for required files
print_step "Checking for CI/CD files..."

required_files=(
    "docker/Dockerfile"
    "docker/entrypoint.sh"
    ".github/workflows/ci-cd.yml"
    ".dockerignore"
)

missing_files=0
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_warning "Missing: $file"
        missing_files=$((missing_files + 1))
    else
        print_success "Found: $file"
    fi
done

if [ $missing_files -gt 0 ]; then
    echo ""
    print_error "Some required files are missing!"
    echo "Please copy all provided files to the correct locations:"
    echo "  - Dockerfile → docker/Dockerfile"
    echo "  - entrypoint.sh → docker/entrypoint.sh"
    echo "  - ci-cd.yml → .github/workflows/ci-cd.yml"
    echo "  - .dockerignore → .dockerignore"
    exit 1
fi

# Step 3: Make entrypoint script executable
print_step "Setting permissions..."
chmod +x docker/entrypoint.sh
print_success "Entrypoint script is now executable"

# Step 4: GitHub configuration check
print_step "Checking GitHub configuration..."

echo ""
echo "Manual steps required:"
echo ""
echo "1. GitHub Personal Access Token (PAT):"
echo "   - Go to: https://github.com/settings/tokens"
echo "   - Click 'Generate new token' → 'Generate new token (classic)'"
echo "   - Give it a name: 'MLC-LLM GHCR Access'"
echo "   - Set expiration as needed"
echo "   - Select scope: 'write:packages'"
echo "   - Generate token and copy it"
echo ""
echo "2. Add GitHub Secret:"
echo "   - Go to your repository settings"
echo "   - Settings → Secrets and variables → Actions"
echo "   - Click 'New repository secret'"
echo "   - Name: GHCR_TOKEN"
echo "   - Value: Paste the PAT from step 1"
echo "   - Click 'Add secret'"
echo ""
echo "3. Enable GitHub Actions:"
echo "   - Go to: Settings → Actions → General"
echo "   - Under 'Workflow permissions'"
echo "   - Select 'Read and write permissions'"
echo "   - Save"
echo ""

read -p "Have you completed all the above steps? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Please complete the GitHub configuration steps, then re-run this script."
    exit 1
fi

print_success "GitHub configuration confirmed"

# Step 5: Test local Docker build (optional)
echo ""
read -p "Would you like to test the Docker build locally? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_step "Building Docker image locally (this may take 10-20 minutes)..."
    
    if docker build -f docker/Dockerfile -t mlc-llm-builder:test .; then
        print_success "Docker image built successfully!"
        
        echo ""
        echo "You can test the image with:"
        echo "  Development mode: docker run -it mlc-llm-builder:test"
        echo "  Build mode:       docker run mlc-llm-builder:test mlc_llm --help"
    else
        print_error "Docker build failed. Please check the error messages above."
        exit 1
    fi
fi

# Step 6: Commit and push
echo ""
print_step "Final steps:"
echo ""
echo "1. Review your changes:"
echo "   git status"
echo ""
echo "2. Add the new files:"
echo "   git add .github/workflows/ci-cd.yml docker/ .dockerignore"
echo ""
echo "3. Commit:"
echo "   git commit -m 'Add CI/CD pipeline for MLC-LLM'"
echo ""
echo "4. Push to GitHub:"
echo "   git push origin main"
echo ""
echo "5. Monitor the workflow:"
echo "   Go to: https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')/actions"
echo ""

print_success "Setup complete!"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "Next: Push your changes to GitHub to trigger the workflow"
echo "═══════════════════════════════════════════════════════════"
echo ""
