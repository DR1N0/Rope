# AMD ROCm Support for Rope

Rope now supports AMD GPUs on Windows using ROCm! This guide will help you set up and run Rope with your AMD Radeon graphics card.

## Requirements

### Hardware
- AMD Radeon RX 7900/9000 series OR
- AMD Radeon AI PRO R9700 OR
- AMD Ryzen AI Max+ 395/390/385 OR
- AMD Ryzen AI 9 HX 375/370 OR
- AMD Ryzen AI 9 365

### Software
- **Python 3.12** - **REQUIRED** (AMD's ROCm wheels are built for Python 3.12 only)
- Windows 11 (64-bit) - **Required**
- Minimum 32GB RAM (64GB recommended)
- AMD Software: PyTorch on Windows Edition 7.1.1 driver

## Installation

### Step 1: Install AMD ROCm Driver

1. Download and install the AMD Software: PyTorch on Windows Edition 7.1.1 driver from:
   https://www.amd.com/en/resources/support-articles/release-notes/RN-AMDGPU-WINDOWS-PYTORCH-7-1-1.html

2. **Important**: Uninstall any existing AMD graphics driver before installing the ROCm driver
   - If issues persist, use the [AMD Cleanup Utility](https://www.amd.com/en/resources/support-articles/faqs/GPU-601.html)

3. Reboot your system after installation

### Step 2: Install uv (Package Manager)

Rope now uses `uv` for faster and more reliable dependency management.

```bash
pip install uv
```

Or download from: https://github.com/astral-sh/uv

### Step 3: Install Rope with ROCm Support

**IMPORTANT**: Do NOT use `uv sync` without specifying an extra - it will try to install all backends simultaneously and fail.

Run the provided installation script instead:

```bash
install-rocm.bat
```

This script will:
- Check for Python 3.12 (required for AMD ROCm) using the Python launcher
- **Create a virtual environment** (`venv-rocm`) with Python 3.12
- Install ROCm SDK components from AMD's repository
- Install PyTorch 2.9.0 with ROCm support from AMD's wheels
- Install all other dependencies
- Set up Rope for AMD GPU usage

**Why not `uv sync --extra rocm`?**
AMD's PyTorch wheels for Windows are hosted on their own repository and use direct wheel URLs, not standard package indexes. The installation script handles this correctly.

**Note about Multiple Python Versions:**
If you have multiple Python versions installed (e.g., 3.13, 3.11, 3.12), the script uses the Windows Python launcher (`py -3.12`) to specifically select Python 3.12 and create an isolated virtual environment. This keeps your AMD ROCm installation separate from other Python environments.

### Step 4: Verify Installation

Run this command to verify ROCm is working:

```bash
python -c "import torch; print(f'ROCm available: {torch.cuda.is_available()}'); print(f'Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"None\"}')"
```

Expected output:
```
ROCm available: True
Device: AMD Radeon RX 7900 XTX  (or your GPU model)
```

## Running Rope

**Important:** If you installed using `install-rocm.bat`, use the ROCm-specific launcher:

```bash
Rope-ROCm.bat
```

This launcher automatically activates the virtual environment and runs Rope.

**Manual activation (advanced):**
```bash
# Activate the virtual environment
venv-rocm\Scripts\activate

# Then run Rope
python Rope.py
```

**Note:** The standard `Rope.bat` launcher won't use the virtual environment and may not work correctly with ROCm.

When Rope starts, you should see GPU information in the console:

```
=== GPU Configuration ===
Device: AMD Radeon RX 7900 XTX
Providers: ['ROCMExecutionProvider', 'CPUExecutionProvider']
Memory: 512MB / 24564MB
========================
```

## Switching Between NVIDIA and AMD

If you have both NVIDIA and AMD GPUs or want to switch between them:

### For NVIDIA CUDA:
```bash
install-cuda.bat
```

### For AMD ROCm:
```bash
install-rocm.bat
```

The system will automatically detect which GPU is active and use the appropriate backend.

## Performance Notes

- ROCm on Windows is relatively new - performance may vary
- Recommended to have 64GB RAM for larger models
- First run may be slower as models are loaded and optimized

## Debugging

If Rope crashes or behaves unexpectedly, use the debug launcher to get detailed logging:

```bash
Rope-ROCm-Debug.bat
```

This provides several debug options:
1. **Verbose logging (-v)** - Shows INFO level logs
2. **Very verbose logging (-vv)** - Shows DEBUG level logs + ONNX Runtime internals
3. **Force CPU mode** - Disables GPU entirely (useful for testing)
4. **Force CPU + verbose** - Combination of CPU mode with detailed logging

### Typical Debug Workflow

1. **First, try verbose logging:**
   ```bash
   Rope-ROCm-Debug.bat
   # Select option 2 (Very verbose)
   ```
   This will show exactly where the crash occurs.

2. **If it crashes during face detection, try CPU mode:**
   ```bash
   Rope-ROCm-Debug.bat
   # Select option 3 (Force CPU)
   ```
   This confirms if it's a ROCMExecutionProvider issue.

3. **Share the logs** when reporting issues - they contain critical diagnostic information.

## Troubleshooting

### "ROCm available: False"
- Ensure you installed the correct AMD driver version (7.1.1)
- Verify your GPU is in the supported list
- Try rebooting your system
- Run the AMD Cleanup Utility and reinstall the driver

### Out of Memory Errors
- Close other applications
- Reduce batch size if applicable
- Consider upgrading to 64GB RAM

### Installation Failures
- Make sure Windows 11 is up to date
- Run the installation script as Administrator
- Check that `uv` is properly installed: `uv --version`

### Smart App Control Warning
- ComfyUI may fail to launch if Smart App Control is enabled
- Disable Smart App Control in Windows Security settings

## Known Issues (from AMD)

- Intermittent out-of-memory errors on Ryzen™ AI Max 300 series
- Corruption in Stable Diffusion 3 on Ryzen AI with 32GB RAM
- ComfyUI launch issues with Smart App Control enabled

## Technical Details

### Device Detection
Rope automatically detects your GPU and configures the appropriate execution provider:
- AMD GPUs (Windows) → DmlExecutionProvider (DirectML)
- AMD GPUs (Linux) → MIGraphXExecutionProvider or ROCMExecutionProvider
- NVIDIA GPUs → CUDAExecutionProvider  
- No GPU → CPUExecutionProvider (fallback)

**Note:** Windows uses DirectML for AMD GPU acceleration with ONNX Runtime. The installation script (`install-rocm.bat`) now installs `onnxruntime-directml` automatically for optimal Windows performance.

### Memory Monitoring
GPU memory monitoring works seamlessly with both NVIDIA and AMD:
- Uses PyTorch's native methods (works for both)
- Falls back to nvidia-smi for NVIDIA if needed
- Displays memory usage in the GUI

## Additional Resources

- [AMD ROCm on Radeon Documentation](https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/index.html)
- [PyTorch ROCm Installation Guide](https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/install/installrad/windows/install-pytorch.html)
- [Beginner's Guide to LLMs with AMD on Windows](https://gpuopen.com/learn/pytorch-windows-amd-llm-guide/)

## Support

For issues specific to Rope on AMD GPUs, please report them in the Rope repository with:
- Your GPU model
- AMD driver version
- Error messages or screenshots
- Steps to reproduce

For ROCm-specific issues, refer to AMD's official support channels.
