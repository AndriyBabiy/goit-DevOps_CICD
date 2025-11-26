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

# Check if running as root OR if sudo is available
check_privileges() {
  if [ "$(id -u)" -eq 0 ]; then
      SUDO=""
  elif command -v sudo > /dev/null 2>&1; then
      SUDO="sudo"
  else
      echo "Error: This script requires root privileges. Please run as root or install sudo."
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

        # Install prerequisites
        $SUDO apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Set up the repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Install Docker Engine
        $SUDO apt-get update
        $SUDO apt-get install -y docker-ce docker-ce-cli containerd.io
    fi
}

# Install Docker Compose
install_docker_compose() {
    if command -v docker-compose > /dev/null 2>&1 || docker compose version > /dev/null 2>&1; then
        print_warning "Docker Compose is already installed"
    else
        print_status "Installing Docker Compose..."
        $SUDO apt-get install -y docker-compose-plugin
    fi
}

# Install Python 3 and pip
install_python() {
    if command -v python3 > /dev/null 2>&1; then
        print_warning "Python3 is already installed: $(python3 --version)"
    else
        print_status "Installing Python3..."
        $SUDO apt-get install -y python3
    fi
}

# Install pip
install_pip() {
    if command -v pip > /dev/null 2>&1; then
        print_warning "pip is already installed: $(python3 --version)"
    else
        print_status "Installing pip..."
        $SUDO apt-get install -y python3-pip
    fi
}

# Install Django
install_django() {
    if python3 -c "import django" > /dev/null 2>&1; then
        print_warning "Django is already installed: $(python3 -m django --version)"
    else
        print_status "Installing Django..."
        pip3 install django
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
    install_pip
    install_django

    print_status "Installation complete!"
}

# Run main function
main