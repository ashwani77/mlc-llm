#!/bin/bash
# MLC-LLM Multi-Purpose Entrypoint Script
# Enables both development mode (interactive) and build mode (CI/CD)

set -e

# Color output for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# =============================================================================
# MODE DETECTION
# =============================================================================

if [ $# -eq 0 ]; then
    # NO ARGUMENTS = DEVELOPMENT MODE (Interactive)
    print_info "============================================"
    print_info "   MLC-LLM Development Environment"
    print_info "============================================"
    print_info ""
    print_info "Environment Details:"
    print_info "  MLC-LLM Source: ${MLC_LLM_SOURCE_DIR}"
    print_info "  Working Dir:    $(pwd)"
    print_info "  Python:         $(python --version)"
    print_info ""
    print_success "Available Commands:"
    print_info "  mlc_llm --help          - MLC-LLM CLI help"
    print_info "  pytest tests/           - Run tests"
    print_info "  cd mlc-llm              - Navigate to source"
    print_info "  python -m mlc_llm       - Alternative CLI invocation"
    print_info ""
    print_success "Development environment ready!"
    print_info "Starting interactive shell..."
    print_info ""
    
    # Start interactive bash shell
    exec /bin/bash

else
    # ARGUMENTS PROVIDED = BUILD MODE (Non-Interactive CI/CD)
    print_info "============================================"
    print_info "   MLC-LLM Build Mode"
    print_info "============================================"
    print_info "Executing command: $@"
    print_info ""
    
    # Change to MLC-LLM directory if needed
    if [ -d "${MLC_LLM_SOURCE_DIR}" ]; then
        cd "${MLC_LLM_SOURCE_DIR}"
        print_info "Working directory: ${MLC_LLM_SOURCE_DIR}"
    fi
    
    # Execute the provided command
    exec "$@"
fi
