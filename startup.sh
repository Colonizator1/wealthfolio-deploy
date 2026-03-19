#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    echo -e "${2}${1}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate Argon2id hash
generate_password_hash() {
    local password="$1"
    local salt="wealthfolio_salt"
    
    # argon2 is guaranteed to be available at this point
    printf '%s' "$password" | argon2 "$salt" -id -e
}

print_message "🚀 Wealthfolio Self-Hosting Setup" "$BLUE"
print_message "================================" "$BLUE"
echo

# Check prerequisites
print_message "Checking prerequisites..." "$YELLOW"
if ! command_exists docker; then
    print_message "ERROR: Docker is not installed. Please install Docker first." "$RED"
    print_message "Visit: https://docs.docker.com/get-docker/" "$BLUE"
    exit 1
fi

if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
    print_message "ERROR: Docker Compose is not available. Please install Docker Compose." "$RED"
    exit 1
fi

if ! command_exists openssl; then
    print_message "ERROR: OpenSSL is not installed. Please install OpenSSL first." "$RED"
    exit 1
fi

# Check and install argon2 if not available
if ! command_exists argon2; then
    print_message "Argon2 not found. Installing..." "$YELLOW"
    
    # Detect OS and install argon2
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install argon2
        else
            print_message "ERROR: Homebrew not found. Please install Homebrew first or install argon2 manually." "$RED"
            print_message "Visit: https://brew.sh/" "$BLUE"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y argon2
        elif command_exists yum; then
            sudo yum install -y argon2
        elif command_exists pacman; then
            sudo pacman -S argon2
        else
            print_message "ERROR: No supported package manager found. Please install argon2 manually." "$RED"
            exit 1
        fi
    else
        print_message "ERROR: Unsupported OS. Please install argon2 manually." "$RED"
        exit 1
    fi
    
    # Verify installation
    if command_exists argon2; then
        print_message "✓ Argon2 installed successfully" "$GREEN"
    else
        print_message "ERROR: Failed to install argon2. Please install it manually." "$RED"
        exit 1
    fi
else
    print_message "✓ Argon2 found" "$GREEN"
fi

print_message "✓ All prerequisites met" "$GREEN"
echo

# Check if .env.docker already exists
if [[ -f ".env.docker" ]]; then
    print_message "Found existing .env.docker file." "$YELLOW"
    read -p "Do you want to regenerate it? (y/N): " REGENERATE
    if [[ "$REGENERATE" != "y" && "$REGENERATE" != "Y" ]]; then
        print_message "Using existing configuration..." "$GREEN"
        SKIP_CONFIG=true
    fi
fi

if [[ "$SKIP_CONFIG" != "true" ]]; then
    # Get configuration from user
    print_message "Configuration Setup" "$YELLOW"
    print_message "==================" "$YELLOW"
    echo

    # Get port for Nginx
    read -p "Enter port for Nginx reverse proxy (default: 80): " NGINX_PORT
    if [[ -z "$NGINX_PORT" ]]; then
        NGINX_PORT="80"
    fi

    # Get password
    while true; do
        read -s -p "Enter a secure password for Wealthfolio login: " PASSWORD
        echo
        if [[ ${#PASSWORD} -lt 8 ]]; then
            print_message "Password must be at least 8 characters long." "$RED"
            continue
        fi
        
        read -s -p "Confirm password: " PASSWORD_CONFIRM
        echo
        if [[ "$PASSWORD" != "$PASSWORD_CONFIRM" ]]; then
            print_message "Passwords do not match. Please try again." "$RED"
            continue
        fi
        break
    done

    # Generate secret key
    print_message "Generating secret key..." "$YELLOW"
    SECRET_KEY=$(openssl rand -base64 32)

    # Generate password hash
    print_message "Generating password hash..." "$YELLOW"
    PASSWORD_HASH=$(generate_password_hash "$PASSWORD")

    # Create .env file
    print_message "Creating .env.docker file..." "$YELLOW"
    cat > .env.docker << EOF
# Server Configuration
WF_LISTEN_ADDR=0.0.0.0:8088
WF_DB_PATH=/data/wealthfolio.db
WF_STATIC_DIR=dist

# Security (Required)
WF_SECRET_KEY=${SECRET_KEY}
WF_SECRET_FILE=/data/secrets.json

# Authentication (Required for web access)
WF_AUTH_PASSWORD_HASH=${PASSWORD_HASH}
WF_AUTH_TOKEN_TTL_MINUTES=480

# Network
WF_CORS_ALLOW_ORIGINS=*
WF_REQUEST_TIMEOUT_MS=30000

# Add-ons
WF_ADDONS_DIR=/data/addons

# Nginx Configuration
NGINX_PORT=${NGINX_PORT}
EOF

    print_message "✓ Configuration file created" "$GREEN"
fi

# Make utility scripts executable
chmod +x backup.sh update.sh

# Pull Docker images
print_message "Pulling Docker images..." "$YELLOW"
docker-compose pull

# Start the services
print_message "Starting Wealthfolio services..." "$YELLOW"
docker-compose up -d

# Wait for services to be ready
print_message "Waiting for services to start..." "$YELLOW"
sleep 10

# Get the nginx port from .env.docker
NGINX_PORT=$(grep "^NGINX_PORT=" .env.docker 2>/dev/null | cut -d'=' -f2 || echo "80")

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_message "✓ Wealthfolio is starting up!" "$GREEN"
    echo
    print_message "📊 Access your Wealthfolio instance at:" "$BLUE"
    print_message "   http://localhost:$NGINX_PORT" "$GREEN"
    echo
    print_message "🔐 Login with the password you set during configuration" "$BLUE"
    echo
    print_message "📋 Useful commands:" "$BLUE"
    print_message "   View logs:    docker-compose logs -f" "$YELLOW"
    print_message "   Stop:         docker-compose down" "$YELLOW"
    print_message "   Update:       ./update.sh" "$YELLOW"
    print_message "   Backup:       ./backup.sh" "$YELLOW"
    echo
    print_message "🗂️  Your data is stored in Docker volume: wealthfolio_deploy_wealthfolio-data" "$BLUE"
    print_message "⚙️  Configuration file: .env.docker" "$BLUE"
    echo
    print_message "🎉 Setup complete! Enjoy using Wealthfolio!" "$GREEN"
else
    print_message "❌ Something went wrong. Check the logs with: docker-compose logs" "$RED"
    exit 1
fi