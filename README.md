
## Building Your Own .so Files

### Prerequisites

1. **Android NDK** (version 27+ recommended)
   ```bash
   # Install via Android Studio or download from:
   # https://developer.android.com/ndk/downloads
   
   export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/yourversion

2. **FFmpeg Source Code**
   ```bash
   #  for AI VIDEO PLAYER app version below 9.0 Download FFmpeg 6.1.1 
   wget https://ffmpeg.org/releases/ffmpeg-6.1.1.tar.xz
   tar xf ffmpeg-6.1.1.tar.xz
   cd ffmpeg-6.1.1
    #  for AI VIDEO PLAYER app version above 9.0 Download FFmpeg 8.1
   wget https://ffmpeg.org/releases/ffmpeg-8.1.tar.xz
   tar xf ffmpeg-8.1.tar.xz
   cd ffmpeg-8.1
   ```

3. **Build Tools**
   ```bash
   sudo apt-get install build-essential yasm nasm pkg-config
   ```

### Build Script: Safe Core
script is already given you can modify to your needs and replace the .so files.



### Critical Build Flags just run the Script don't need to look here that much.

| Flag | Purpose | Requirement |
|------|---------|-------------|
| `--enable-shared` | Build .so files (not static .a) | **Required** for LGPL you do not need to follow this |
| `--disable-static` | Don't build static libraries  |
| `-fPIC` | Position Independent Code | **Required** |
| `-Wl,-z,max-page-size=16384` | 16KB page alignment | **Required for Android 15+** |



### ZIP Structure

Create a ZIP file with this structure:

```
ffmpeg-codecs-arm64-v8a.zip
├── metadata.json           # Build information
└── arm64-v8a/              # ABI folder
    ├── libavutil.so
    ├── libswresample.so
    ├── libavcodec.so
    ├── libavformat.so
    ├── libswscale.so
    └── libavfilter.so
```

