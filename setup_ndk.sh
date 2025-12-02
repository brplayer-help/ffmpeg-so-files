#!/bin/bash
#
# Android NDK Setup Script
# Downloads and configures the Android NDK for FFmpeg cross-compilation
#
# Usage:
#   ./setup_ndk.sh          # Install latest stable NDK
#   ./setup_ndk.sh r26b     # Install specific NDK version
#

set -e

# Default NDK version (LTS recommended for FFmpeg builds)
DEFAULT_NDK_VERSION="r26b"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NDK_INSTALL_DIR="${HOME}/Android/Sdk/ndk"

# ============================================================================
# Functions
# ============================================================================

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="linux" ;;
        Darwin*)    OS="darwin" ;;
        MINGW*|MSYS*|CYGWIN*)    OS="windows" ;;
        *)          echo "Unsupported OS"; exit 1 ;;
    esac
    echo "Detected OS: $OS"
}

download_ndk() {
    local VERSION=$1
    local NDK_DIR="${NDK_INSTALL_DIR}/android-ndk-${VERSION}"
    
    if [ -d "$NDK_DIR" ]; then
        echo "NDK ${VERSION} already installed at $NDK_DIR"
        return 0
    fi
    
    echo "Downloading Android NDK ${VERSION}..."
    
    # NDK download URL
    local URL="https://dl.google.com/android/repository/android-ndk-${VERSION}-${OS}.zip"
    local ZIP_FILE="/tmp/android-ndk-${VERSION}.zip"
    
    # Download
    echo "URL: $URL"
    wget -O "$ZIP_FILE" "$URL" || curl -L -o "$ZIP_FILE" "$URL" || {
        echo "ERROR: Failed to download NDK"
        return 1
    }
    
    # Create install directory
    mkdir -p "$NDK_INSTALL_DIR"
    
    # Extract
    echo "Extracting NDK..."
    unzip -q "$ZIP_FILE" -d "$NDK_INSTALL_DIR" || {
        echo "ERROR: Failed to extract NDK"
        rm -f "$ZIP_FILE"
        return 1
    }
    
    # Rename to version-only name if needed
    if [ -d "${NDK_INSTALL_DIR}/android-ndk-${VERSION}" ]; then
        mv "${NDK_INSTALL_DIR}/android-ndk-${VERSION}" "${NDK_INSTALL_DIR}/${VERSION}"
    fi
    
    # Clean up
    rm -f "$ZIP_FILE"
    
    echo "NDK ${VERSION} installed to ${NDK_INSTALL_DIR}/${VERSION}"
}

setup_environment() {
    local VERSION=$1
    local NDK_PATH="${NDK_INSTALL_DIR}/${VERSION}"
    
    if [ ! -d "$NDK_PATH" ]; then
        NDK_PATH="${NDK_INSTALL_DIR}/android-ndk-${VERSION}"
    fi
    
    if [ ! -d "$NDK_PATH" ]; then
        echo "ERROR: NDK not found at expected location"
        return 1
    fi
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              NDK Setup Complete                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "NDK installed at: $NDK_PATH"
    echo ""
    echo "To use this NDK, add the following to your shell profile:"
    echo ""
    echo "  export ANDROID_NDK_HOME=\"$NDK_PATH\""
    echo "  export ANDROID_NDK=\"\$ANDROID_NDK_HOME\""
    echo "  export PATH=\"\$ANDROID_NDK_HOME:\$PATH\""
    echo ""
    echo "For bash, run:"
    echo "  echo 'export ANDROID_NDK_HOME=\"$NDK_PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo ""
    echo "Or export for current session:"
    echo "  export ANDROID_NDK_HOME=\"$NDK_PATH\""
    echo ""
    
    # Create env file for sourcing
    local ENV_FILE="${SCRIPT_DIR}/ndk_env.sh"
    cat > "$ENV_FILE" << EOF
#!/bin/bash
# Auto-generated NDK environment
export ANDROID_NDK_HOME="$NDK_PATH"
export ANDROID_NDK="\$ANDROID_NDK_HOME"
export PATH="\$ANDROID_NDK_HOME:\$PATH"
EOF
    chmod +x "$ENV_FILE"
    
    echo "You can also source the environment directly:"
    echo "  source $ENV_FILE"
    echo ""
}

verify_ndk() {
    local NDK_PATH=$1
    
    echo "Verifying NDK installation..."
    
    # Check for key files
    local required_files=(
        "toolchains/llvm/prebuilt/${OS}-x86_64/bin/clang"
        "toolchains/llvm/prebuilt/${OS}-x86_64/bin/clang++"
        "toolchains/llvm/prebuilt/${OS}-x86_64/bin/llvm-ar"
    )
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$NDK_PATH/$file" ]; then
            echo "Warning: Expected file not found: $file"
        fi
    done
    
    # Get NDK version
    if [ -f "$NDK_PATH/source.properties" ]; then
        echo ""
        echo "NDK Properties:"
        cat "$NDK_PATH/source.properties"
    fi
    
    echo ""
    echo "NDK verification complete"
}

list_installed_ndks() {
    echo "Installed NDKs:"
    echo ""
    
    if [ -d "$NDK_INSTALL_DIR" ]; then
        for ndk in "$NDK_INSTALL_DIR"/*; do
            if [ -d "$ndk" ]; then
                local name=$(basename "$ndk")
                local version="unknown"
                if [ -f "$ndk/source.properties" ]; then
                    version=$(grep "Pkg.Revision" "$ndk/source.properties" 2>/dev/null | cut -d'=' -f2 | tr -d ' ')
                fi
                echo "  - $name (revision: $version)"
            fi
        done
    else
        echo "  No NDKs installed in $NDK_INSTALL_DIR"
    fi
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    local VERSION=${1:-$DEFAULT_NDK_VERSION}
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Android NDK Setup Script                          ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    case $VERSION in
        list)
            detect_os
            list_installed_ndks
            exit 0
            ;;
        verify)
            detect_os
            if [ -n "$ANDROID_NDK_HOME" ]; then
                verify_ndk "$ANDROID_NDK_HOME"
            else
                echo "ANDROID_NDK_HOME not set"
                list_installed_ndks
            fi
            exit 0
            ;;
        help|--help|-h)
            echo "Usage: $0 [VERSION|list|verify]"
            echo ""
            echo "Commands:"
            echo "  <VERSION>  Download and install specific NDK version (e.g., r26b)"
            echo "  list       List installed NDKs"
            echo "  verify     Verify current NDK installation"
            echo ""
            echo "Examples:"
            echo "  $0            # Install default NDK ($DEFAULT_NDK_VERSION)"
            echo "  $0 r26b       # Install NDK r26b"
            echo "  $0 r25c       # Install NDK r25c"
            echo "  $0 list       # List installed NDKs"
            exit 0
            ;;
    esac
    
    detect_os
    
    echo "Installing NDK version: $VERSION"
    echo "Install directory: $NDK_INSTALL_DIR"
    echo ""
    
    download_ndk "$VERSION"
    verify_ndk "${NDK_INSTALL_DIR}/${VERSION}"
    setup_environment "$VERSION"
}

main "$@"
