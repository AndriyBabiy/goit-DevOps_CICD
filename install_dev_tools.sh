#!/bin/bash

# ===========================================
# Development Tools Installation Script
# ===========================================
# This script installs Docker, Docker Compose,
# Python 3, and Django on Ubuntu/Debian systems
# ===========================================

# Exit on any error
set -e

# Color codes for output (optional but nice)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running with sudo/root privileges
check_privileges() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run this script with sudo"
        exit 1
    fi
}

# Update package lists
update_packages() {
    print_status "Updating package lists..."
    apt-get update -y
}

# Install Docker
install_docker() {
    if command -v docker > /dev/null 2>&1; then
        print_warning "Docker is already installed: $(docker --version)"
    else
        print_status "Installing Docker..."
        # Your installation commands here
    fi
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker-compose > /dev/null 2>&1 || docker compose version > /dev/null 2>&1; then
        print_warning "Docker Compose is already installed"
    else
        print_status "Installing Docker Compose..."
        # Your installation commands here
    fi
}

# Install Python 3
install_python() {
    if command -v python3 > /dev/null 2>&1; then
        print_warning "Python3 is already installed: $(python3 --version)"
    else
        print_status "Installing Python3..."
        # Your installation commands here
    fi
}

# Install Django
install_django() {
    if python3 -c "import django" > /dev/null 2>&1; then
        print_warning "Django is already installed: $(python3 -m django --version)"
    else
        print_status "Installing Django..."
        # Your installation commands here
    fi
}

# Main execution
main() {
    print_status "Starting development tools installation..."

    check_privileges
    update_packages
    install_docker
    install_docker_compose
    install_python
    install_django

    print_status "Installation complete!"
}

# Run main function
main