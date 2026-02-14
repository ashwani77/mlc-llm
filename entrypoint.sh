#!/bin/bash
# Entrypoint script for MLC-LLM Docker image
# Makes the image multi-purpose: development mode or build mode

set -e

# Function to print colored output
print_info() {
    echo -e "\033[0;36m[INFO]\033[0m $1"
}

print_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    # No arguments = Development mode
    print_info "Starting MLC-LLM Development Environment"
    print_info "=========================================="
    print_info ""
    print_info "MLC-LLM source code: ${MLC_LLM_SOURCE_DIR}"
    print_info "Working directory: $(pwd)"
    print_info ""
    print_info "Useful commands:"
    print_info "  - mlc_llm --help          : Show MLC-LLM help"
    print_info "  - cd mlc-llm              : Go to source directory"
    print_info "  - pytest tests/           : Run tests"
    print_info "  - python setup.py build   : Build the package"
    print_info ""
    print_success "Development environment ready!"
    print_info "Starting interactive shell..."
    print_info ""
    
    # Start interactive bash shell
    exec /bin/bash
else
    # Arguments provided = Build mode (non-interactive)
    print_info "Running in Build Mode"
    print_info "Command: $@"
    print_info ""
    
    # Change to MLC-LLM directory
    cd "${MLC_LLM_SOURCE_DIR}"
    
    # Execute the provided command
    exec "$@"
fi
