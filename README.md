
## Building Your Own .so Files

### Prerequisites

1. **Android NDK** (version 26.1+ recommended)
   ```bash
   # Install via Android Studio or download from:
   # https://developer.android.com/ndk/downloads
   
   export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/26.1.10909125
   ```

2. **FFmpeg Source Code**
   ```bash
   # Download FFmpeg 6.1.1 (or desired version)
   wget https://ffmpeg.org/releases/ffmpeg-6.1.1.tar.xz
   tar xf ffmpeg-6.1.1.tar.xz
   cd ffmpeg-6.1.1
   ```

3. **Build Tools**
   ```bash
   sudo apt-get install build-essential yasm nasm pkg-config
   ```

### Build Script: Safe Core
script is already given you can modify to your needs and replace the .so files.



### Critical Build Flags

| Flag | Purpose | Requirement |
|------|---------|-------------|
| `--enable-shared` | Build .so files (not static .a) | **Required** for LGPL |
| `--disable-static` | Don't build static libraries | Recommended |
| `-fPIC` | Position Independent Code | **Required** |
| `-Wl,-z,max-page-size=16384` | 16KB page alignment | **Required for Android 15+** |



### ZIP Structure

Create a ZIP file with this structure:

```
ffmpeg-codecs-arm64-v8a-6.1.1.zip
├── metadata.json           # Build information
└── arm64-v8a/              # ABI folder (optional, files can be at root)
    ├── libavutil.so
    ├── libswresample.so
    ├── libavcodec.so
    ├── libavformat.so
    ├── libswscale.so
    └── libavfilter.so
```

