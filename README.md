# Custom Codec Pack Builder

This guide helps you compile a custom codec pack containing decoders/encoders that are missing or unsupported on your specific Android device. The build runs privately on GitHub's infrastructure and outputs a ZIP file you can import directly into the app.

---

## Ask GitHub Copilot or AI Assistant

To get the exact build parameters for your device, copy and paste this simple instruction into your AI chat:

**Prompt for the AI:**
"I want to build a custom codec pack for my Android device: **[INSERT YOUR DEVICE NAME HERE]** (e.g., Pixel 8, Samsung S24).
I need support for media formats/codecs that are currently unsupported or failing to play on my device.

Please:
1. Identify the CPU architecture (ABI) of my device.
2. Generate the minimal FFmpeg configure flags to enable the necessary decoders/encoders for the missing formats.
3. Provide the exact input parameters I should type into the manual GitHub Actions workflow (`build-ffmpeg.yml`). Configure it to build ONLY for my device's architecture to save build time and compute."

---

## How to Build (AI Agent Tasks) If user in ask mode user has to do things manually.

1. **Trigger the Build**:
   - Go to the **Actions** tab in your GitHub repository.
   - Select the **Build FFmpeg (.yml) file** workflow.
   - Click **Run workflow**, set the branch, and select `custom` as the build type.
   - Set **architectures** to the architecture identified by the AI as per Device name identify (e.g., `arm64-v8a`).
   - Configure flags as per devices missing things into **custom_configure_flags**.
   - Click **Run workflow**.

2. **Download and Import**(User Tasks):
   - Once complete, download the generated ZIP artifact from the run summary.
   - Copy the ZIP file to your device.
   - Open the player, go to **Settings ➔ Codec Pack ➔ Import**, and select the ZIP file. The app will extract and load your custom dynamic libraries automatically.
