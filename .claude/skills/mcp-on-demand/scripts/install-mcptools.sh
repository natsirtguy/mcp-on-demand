#!/bin/bash
set -euo pipefail

# Script to install mcptools (mcp CLI) for interacting with MCP servers
# https://github.com/f/mcptools

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if mcptools is already installed
check_installed() {
    if command -v mcp &> /dev/null; then
        log_info "mcptools is already installed: $(which mcp)"
        mcp --version 2>/dev/null || true
        return 0
    fi

    # Also check for mcptools binary name
    if command -v mcptools &> /dev/null; then
        log_info "mcptools is already installed as 'mcptools': $(which mcptools)"
        log_info "Creating alias 'mcp' -> 'mcptools'"
        return 0
    fi

    return 1
}

# Install via Homebrew (macOS)
install_homebrew() {
    log_info "Installing mcptools via Homebrew..."

    if ! command -v brew &> /dev/null; then
        log_error "Homebrew is not installed. Please install Homebrew first."
        return 1
    fi

    brew tap f/mcptools
    brew install mcp

    log_info "mcptools installed successfully via Homebrew"
}

# Install via Go
install_go() {
    log_info "Installing mcptools via Go..."

    if ! command -v go &> /dev/null; then
        log_warn "Go is not installed. Attempting to install Go first..."
        install_go_lang
    fi

    go install github.com/f/mcptools/cmd/mcptools@latest

    # The binary is installed as 'mcptools', create symlink or alias
    GOPATH="${GOPATH:-$HOME/go}"
    if [ -f "$GOPATH/bin/mcptools" ]; then
        log_info "mcptools installed at $GOPATH/bin/mcptools"

        # Create symlink if mcp doesn't exist
        if [ ! -f "$GOPATH/bin/mcp" ]; then
            ln -sf "$GOPATH/bin/mcptools" "$GOPATH/bin/mcp"
            log_info "Created symlink: mcp -> mcptools"
        fi

        # Ensure GOPATH/bin is in PATH
        if [[ ":$PATH:" != *":$GOPATH/bin:"* ]]; then
            log_warn "Add $GOPATH/bin to your PATH:"
            log_warn "  export PATH=\"\$PATH:$GOPATH/bin\""
            export PATH="$PATH:$GOPATH/bin"
        fi
    fi

    log_info "mcptools installed successfully via Go"
}

# Install Go language
install_go_lang() {
    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    local GO_VERSION="1.22.0"
    local GO_TAR="go${GO_VERSION}.${OS}-${ARCH}.tar.gz"
    local GO_URL="https://go.dev/dl/${GO_TAR}"

    log_info "Downloading Go ${GO_VERSION}..."

    if command -v curl &> /dev/null; then
        curl -LO "$GO_URL"
    elif command -v wget &> /dev/null; then
        wget "$GO_URL"
    else
        log_error "Neither curl nor wget is available"
        return 1
    fi

    log_info "Installing Go to /usr/local/go..."
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "$GO_TAR"
    rm "$GO_TAR"

    export PATH="$PATH:/usr/local/go/bin"
    export GOPATH="${GOPATH:-$HOME/go}"
    export PATH="$PATH:$GOPATH/bin"

    log_info "Go installed: $(go version)"
}

# Download pre-built binary from GitHub releases
install_from_release() {
    log_info "Installing mcptools from GitHub releases..."

    local OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *) log_error "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    # Get latest release
    local RELEASE_URL="https://api.github.com/repos/f/mcptools/releases/latest"
    local DOWNLOAD_URL

    if command -v curl &> /dev/null; then
        DOWNLOAD_URL=$(curl -s "$RELEASE_URL" | grep "browser_download_url.*${OS}.*${ARCH}" | head -1 | cut -d '"' -f 4)
    else
        log_error "curl is required to download from GitHub releases"
        return 1
    fi

    if [ -z "$DOWNLOAD_URL" ]; then
        log_warn "No pre-built binary found for ${OS}-${ARCH}, falling back to Go install"
        return 1
    fi

    local INSTALL_DIR="${HOME}/.local/bin"
    mkdir -p "$INSTALL_DIR"

    log_info "Downloading from: $DOWNLOAD_URL"
    curl -L "$DOWNLOAD_URL" -o "$INSTALL_DIR/mcp"
    chmod +x "$INSTALL_DIR/mcp"

    # Ensure install dir is in PATH
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        export PATH="$PATH:$INSTALL_DIR"
        log_warn "Add $INSTALL_DIR to your PATH permanently"
    fi

    log_info "mcptools installed to $INSTALL_DIR/mcp"
}

# Main installation logic
main() {
    log_info "mcptools installer - https://github.com/f/mcptools"
    echo ""

    # Check if already installed
    if check_installed; then
        log_info "mcptools is ready to use!"
        return 0
    fi

    local OS=$(uname -s)

    case "$OS" in
        Darwin)
            # macOS - prefer Homebrew
            if command -v brew &> /dev/null; then
                install_homebrew
            else
                install_go
            fi
            ;;
        Linux)
            # Linux - try release first, then Go
            if ! install_from_release; then
                install_go
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows
            install_go
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    # Verify installation
    echo ""
    if command -v mcp &> /dev/null; then
        log_info "Installation successful!"
        log_info "mcp location: $(which mcp)"
        mcp --version 2>/dev/null || true
    elif command -v mcptools &> /dev/null; then
        log_info "Installation successful!"
        log_info "mcptools location: $(which mcptools)"
        log_info "Use 'mcptools' or create an alias: alias mcp=mcptools"
    else
        log_error "Installation may have failed. Please check your PATH."
        exit 1
    fi
}

main "$@"
