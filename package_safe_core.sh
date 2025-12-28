#!/bin/bash
#
# Package Safe Core LGPL FFmpeg Libraries into ZIP for Dynamic Loader
# 
# This script builds and packages the SAFE CORE FFmpeg .so files
# with LGPL-only royalty-free codecs (Opus, Vorbis, FLAC, VP8/VP9, AV1, etc.)
#
# Output: ffmpeg-build/packages/safe-core/<abi>/
#
# Usage:
#   ./package_safe_core.sh              # Build for arm64-v8a (default)
#   ./package_safe_core.sh arm64-v8a    # Build for arm64
#   ./package_safe_core.sh armeabi-v7a  # Build for arm32
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${SCRIPT_DIR}/.."
FFMPEG_SRC="${BUILD_ROOT}/ffmpeg-6.1.1"
OUTPUT_DIR="${BUILD_ROOT}/packages/safe-core"

# FFmpeg version
FFMPEG_VERSION="6.1.1"

# Target architecture (default: arm64-v8a)
TARGET_ARCH="${1:-arm64-v8a}"

# NDK setup
export ANDROID_NDK_HOME="${ANDROID_NDK_HOME:-$HOME/Android/Sdk/ndk/26.1.10909125}"
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"
export PATH="$TOOLCHAIN/bin:$PATH"

# Create strip symlinks for make install (workaround for version suffix)
create_strip_symlinks() {
    if [ ! -f "$TOOLCHAIN/bin/aarch64-linux-android24-strip" ]; then
        ln -sf "$TOOLCHAIN/bin/llvm-strip" "$TOOLCHAIN/bin/aarch64-linux-android24-strip" 2>/dev/null || true
    fi
    if [ ! -f "$TOOLCHAIN/bin/armv7a-linux-androideabi24-strip" ]; then
        ln -sf "$TOOLCHAIN/bin/llvm-strip" "$TOOLCHAIN/bin/armv7a-linux-androideabi24-strip" 2>/dev/null || true
    fi
}

# ============================================================================
# Architecture Configuration
# ============================================================================

configure_arch() {
    case $TARGET_ARCH in
        arm64-v8a|arm64)
            ARCH="aarch64"
            CPU="armv8-a"
            CROSS_PREFIX="aarch64-linux-android"
            API=24
            ABI_DIR="arm64-v8a"
            # ARM64 has NEON by default (mandatory in ARMv8)
            EXTRA_CFLAGS="-march=armv8-a -mtune=cortex-a53"
            EXTRA_CONFIGURE="--enable-neon"
            ;;
        armeabi-v7a|arm|arm32)
            ARCH="arm"
            CPU="armv7-a"
            CROSS_PREFIX="armv7a-linux-androideabi"
            API=24
            ABI_DIR="armeabi-v7a"
            # Enable NEON for armv7 - AAB will deliver to NEON-capable devices only
            # Note: -mfloat-abi=softfp removed - NDK r24+ uses hard float by default
            EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mtune=cortex-a8"
            EXTRA_CONFIGURE="--enable-neon"
            ;;
        x86_64)
            ARCH="x86_64"
            CPU="x86-64"
            CROSS_PREFIX="x86_64-linux-android"
            API=24
            ABI_DIR="x86_64"
            EXTRA_CFLAGS="-march=x86-64 -msse4.2"
            EXTRA_CONFIGURE=""
            ;;
        x86)
            ARCH="i686"
            CPU="i686"
            CROSS_PREFIX="i686-linux-android"
            API=24
            ABI_DIR="x86"
            EXTRA_CFLAGS="-march=i686 -msse3"
            EXTRA_CONFIGURE=""
            ;;
        *)
            echo "ERROR: Unsupported architecture: $TARGET_ARCH"
            exit 1
            ;;
    esac
    
    CC="${CROSS_PREFIX}${API}-clang"
    CXX="${CROSS_PREFIX}${API}-clang++"
}

# ============================================================================
# Build FFmpeg
# ============================================================================

build_ffmpeg() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║      Building Safe Core FFmpeg for ${ABI_DIR}                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    cd "$FFMPEG_SRC"
    
    # Clean previous build
    make clean 2>/dev/null || true
    make distclean 2>/dev/null || true
    
    # Force unversioned .so files for Android compatibility
    # Android's dynamic linker expects libavcodec.so, not libavcodec.so.61
    echo "Patching configure for unversioned shared libraries..."
    sed -i "s/SLIBNAME_WITH_MAJOR='\$(SLIBNAME).\$(LIBMAJOR)'/SLIBNAME_WITH_MAJOR='\$(SLIBNAME)'/g" configure
    sed -i "s/SLIB_INSTALL_NAME='\$(SLIBNAME_WITH_VERSION)'/SLIB_INSTALL_NAME='\$(SLIBNAME)'/g" configure
    sed -i "s/SLIB_INSTALL_LINKS='\$(SLIBNAME_WITH_MAJOR) \$(SLIBNAME)'/SLIB_INSTALL_LINKS='\$(SLIBNAME)'/g" configure
    
    # Configure for Safe Core - ROYALTY-FREE CODECS ONLY
    # 
    # IMPORTANT: This build excludes ALL patented codecs for Play Store safety:
    #   - NO DTS (patent-encumbered)
    #   - NO TrueHD/MLP (patent-encumbered)  
    #   - NO AC3/E-AC3 (Dolby patents)
    #   - NO AAC (patent pool)
    #   - NO H.264/H.265 (patent pool)
    #   - NO MPEG-2/MPEG-4 (patent pool)
    #   - NO MP3 encoder (decoder is patent-free since 2017)
    #
    # INCLUDED (royalty-free):
    #   Audio: Opus, Vorbis, FLAC, ALAC, PCM, MP3 decoder
    #   Video: VP8, VP9, AV1, Theora
    #
    # Users can import codec pack for patented codecs via Settings > Codec Pack
    #
    # NEON/SIMD optimizations enabled for better performance
    #
    ./configure \
        --prefix="${OUTPUT_DIR}/${ABI_DIR}" \
        --enable-cross-compile \
        --cross-prefix="${CROSS_PREFIX}${API}-" \
        --target-os=android \
        --arch=${ARCH} \
        --cpu=${CPU} \
        --cc=${CC} \
        --cxx=${CXX} \
        --enable-shared \
        --disable-static \
        --disable-doc \
        --disable-programs \
        --disable-symver \
        --enable-pic \
        --enable-jni \
        --enable-mediacodec \
        --enable-asm \
        --enable-inline-asm \
        ${EXTRA_CONFIGURE} \
        --enable-lto \
        --disable-gpl \
        --disable-nonfree \
        --disable-decoders \
        --disable-encoders \
        --disable-parsers \
        --disable-demuxers \
        --disable-muxers \
        --disable-bsfs \
        --disable-filters \
        --enable-filter=aformat,anull,atrim,format,null,trim,scale,volume \
        --enable-decoder=opus,vorbis,flac,alac,mp3,mp2,mp1 \
        --enable-decoder=pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_s32le,pcm_f32le,pcm_f64le \
        --enable-decoder=pcm_mulaw,pcm_alaw,pcm_u8,pcm_s8 \
        --enable-decoder=wavpack,ape \
        --enable-decoder=vp8,vp9,av1,theora \
        --enable-decoder=mjpeg,rawvideo,gif,png,webp,bmp \
        --enable-parser=opus,vorbis,flac,vp8,vp9,av1,mpegaudio \
        --enable-demuxer=ogg,flac,wav,matroska,webm,mp3,gif,apng,image2,concat,mov,mp4,m4v,avi \
        --enable-muxer=matroska,webm,mp4,mov,ogg,flac,wav,null \
        --enable-protocol=file,http,https,concat,data,pipe \
        --enable-swresample \
        --enable-swscale \
        --extra-cflags="-O3 -fPIC -DANDROID ${EXTRA_CFLAGS:-}" \
        --extra-ldflags="-Wl,-z,max-page-size=16384"
    
    echo ""
    echo "Building FFmpeg (this may take a few minutes)..."
    make -j$(nproc)
    
    echo ""
    echo "Installing to ${OUTPUT_DIR}/${ABI_DIR}..."
    make install
    
    echo ""
    echo "Build complete!"
}

# ============================================================================
# Generate metadata.json
# ============================================================================

generate_metadata() {
    local LIB_DIR="${OUTPUT_DIR}/${ABI_DIR}/lib"
    local METADATA_FILE="${LIB_DIR}/metadata.json"
    
    local BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Determine NEON status
    local NEON_STATUS="false"
    if [[ "${ABI_DIR}" == "arm64-v8a" ]] || [[ "${ABI_DIR}" == "armeabi-v7a" ]]; then
        NEON_STATUS="true"
    fi
    
    cat > "$METADATA_FILE" << EOF
{
    "format_version": 1,
    "ffmpeg_version": "${FFMPEG_VERSION}",
    "build_type": "safe-core",
    "build_label": "Safe Core (Royalty-Free, NEON Optimized)",
    "license": "LGPL-2.1",
    "abi": "${ABI_DIR}",
    "build_date": "${BUILD_DATE}",
    "min_android_api": 24,
    "16kb_aligned": true,
    "neon_enabled": ${NEON_STATUS},
    "note": "Royalty-free codecs only with NEON/SIMD optimizations. No patented codecs (DTS, TrueHD, AC3, AAC, H.264, H.265).",
    "codecs_audio": "opus,vorbis,flac,alac,mp3,pcm_*,wavpack,ape",
    "codecs_video": "vp8,vp9,av1,theora,mjpeg,rawvideo,gif,png,webp,bmp",
    "excluded_patented": "dca,truehd,mlp,ac3,eac3,aac,h264,hevc,mpeg2video,mpeg4",
    "required_libraries": [
        "libavutil.so",
        "libswresample.so",
        "libavcodec.so",
        "libavformat.so",
        "libswscale.so",
        "libavfilter.so"
    ]
}
EOF
    
    echo "Generated metadata.json"
}

# ============================================================================
# Verify Build
# ============================================================================

verify_build() {
    local LIB_DIR="${OUTPUT_DIR}/${ABI_DIR}/lib"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    VERIFYING BUILD                             ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check required libraries
    local REQUIRED_LIBS=("libavutil.so" "libswresample.so" "libavcodec.so" "libavformat.so" "libswscale.so" "libavfilter.so")
    local ALL_PRESENT=1
    
    echo "Checking required libraries in: ${LIB_DIR}"
    echo ""
    
    for lib in "${REQUIRED_LIBS[@]}"; do
        if [ -f "${LIB_DIR}/${lib}" ]; then
            local SIZE=$(ls -lh "${LIB_DIR}/${lib}" | awk '{print $5}')
            echo "  ✓ ${lib} (${SIZE})"
        else
            echo "  ✗ ${lib} - MISSING!"
            ALL_PRESENT=0
        fi
    done
    
    echo ""
    
    if [ $ALL_PRESENT -eq 0 ]; then
        echo "ERROR: Some required libraries are missing!"
        exit 1
    fi
    
    # Show all .so files
    echo "All .so files:"
    ls -lh "${LIB_DIR}"/*.so 2>/dev/null || echo "No .so files found"
    
    echo ""
}

# ============================================================================
# Create ZIP Package
# ============================================================================

create_zip_package() {
    local LIB_DIR="${OUTPUT_DIR}/${ABI_DIR}/lib"
    local ZIP_FILE="${OUTPUT_DIR}/safe-core-${ABI_DIR}.zip"
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                CREATING ZIP PACKAGE                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Remove old zip if exists
    rm -f "$ZIP_FILE"
    
    # Create zip with .so files and metadata
    cd "$LIB_DIR"
    zip -r "$ZIP_FILE" ./*.so ./metadata.json
    
    local ZIP_SIZE=$(ls -lh "$ZIP_FILE" | awk '{print $5}')
    echo ""
    echo "Created: $ZIP_FILE ($ZIP_SIZE)"
}

# ============================================================================
# Main
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║     SAFE CORE (LGPL) CODEC BUILDER & PACKAGER                  ║"
    echo "║                                                                ║"
    echo "║  Builds FFmpeg with royalty-free codecs only                   ║"
    echo "║  (Opus, Vorbis, FLAC, VP8/VP9, AV1, etc.)                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Target: ${TARGET_ARCH}"
    echo "FFmpeg: ${FFMPEG_VERSION}"
    echo "Output: ${OUTPUT_DIR}/${TARGET_ARCH}"
    echo ""
    
    # Check NDK
    if [ ! -d "$ANDROID_NDK_HOME" ]; then
        echo "ERROR: Android NDK not found at: $ANDROID_NDK_HOME"
        echo "Set ANDROID_NDK_HOME environment variable"
        exit 1
    fi
    echo "NDK: $ANDROID_NDK_HOME"
    
    # Check FFmpeg source
    if [ ! -d "$FFMPEG_SRC" ]; then
        echo "ERROR: FFmpeg source not found at: $FFMPEG_SRC"
        exit 1
    fi
    
    # Configure for target architecture
    configure_arch
    
    # Create output directory
    mkdir -p "${OUTPUT_DIR}/${ABI_DIR}"
    
    # Create strip symlinks
    create_strip_symlinks
    
    # Build FFmpeg
    build_ffmpeg
    
    # Generate metadata
    generate_metadata
    
    # Verify build
    verify_build
    
    # Create ZIP package for dynamic loader
    create_zip_package
    
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    BUILD COMPLETE                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Output directory: ${OUTPUT_DIR}/${ABI_DIR}/lib"
    echo "ZIP package: ${OUTPUT_DIR}/safe-core-${ABI_DIR}.zip"
    echo ""
    echo "To use these codecs:"
    echo "  1. Import the ZIP in brplayer → Settings → Codec Pack → Import"
    echo "  2. Or copy .so files to app/src/main/jniLibs/${ABI_DIR}/"
    echo ""
}

main "$@"
