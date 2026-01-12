@echo off

REM Enable logging to file
set LOGFILE=install-rocm-log.txt
echo Installation started at %date% %time% > %LOGFILE%

echo ==========================================
echo Rope Installation - AMD ROCm Support
echo ==========================================
echo.
echo REQUIREMENTS:
echo - Windows 11 (64-bit)
echo - AMD Radeon RX 7900/9000 series OR AMD Ryzen AI processors
echo - AMD Software: PyTorch on Windows Edition 7.1.1 driver installed
echo - Minimum 32GB RAM (64GB recommended)
echo.
echo Please ensure you have installed the AMD driver from:
echo https://www.amd.com/en/resources/support-articles/release-notes/RN-AMDGPU-WINDOWS-PYTORCH-7-1-1.html
echo.
echo Installation log will be saved to: %LOGFILE%
echo.
pause

REM Check if uv is installed
where uv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: uv is not installed!
    echo.
    echo Please install uv first:
    echo   pip install uv
    echo.
    echo Or download from: https://github.com/astral-sh/uv
    pause
    exit /b 1
)

echo Installing dependencies with AMD ROCm support...
echo.

REM Check if Python 3.12 is available via Python launcher
py -3.12 --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python 3.12 not found!
    echo.
    echo AMD ROCm requires Python 3.12 specifically.
    echo You have other Python versions installed, but not 3.12.
    echo.
    echo Please install Python 3.12 from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    echo Your current default Python version:
    python --version 2>nul || echo No default Python found
    echo.
    pause
    exit /b 1
)

echo Found Python 3.12:
py -3.12 --version

REM Check if virtual environment already exists
if exist "venv-rocm\" (
    echo.
    echo Virtual environment already exists!
    echo.
    echo [1] Reuse existing environment ^(skip downloads^)
    echo [2] Delete and recreate ^(fresh install^)
    echo.
    choice /C 12 /N /M "Select option (1 or 2): "
    if errorlevel 2 (
        echo.
        echo Deleting existing virtual environment...
        rmdir /s /q venv-rocm
        if exist "venv-rocm\" (
            echo ERROR: Failed to delete venv-rocm directory!
            echo Please close any programs using it and try again.
            pause
            exit /b 1
        )
        goto CREATE_VENV
    ) else (
        goto ACTIVATE_VENV
    )
)

:CREATE_VENV
echo.
echo Creating virtual environment with Python 3.12...
py -3.12 -m venv venv-rocm
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to create virtual environment!
    echo.
    echo Make sure Python 3.12 has venv module installed.
    echo You can reinstall Python 3.12 with default components.
    pause
    exit /b 1
)

:ACTIVATE_VENV
REM Activate virtual environment
echo Activating virtual environment...
call venv-rocm\Scripts\activate.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to activate virtual environment!
    pause
    exit /b 1
)

echo.
echo Virtual environment activated. Using:
python --version
echo.

REM Check if this is a reused environment
set SKIP_DOWNLOADS=0
if exist "venv-rocm\Lib\site-packages\torch" (
    echo.
    echo Checking existing installation...
    python -c "import torch" 2>nul
    if %ERRORLEVEL% EQU 0 (
        echo PyTorch already installed. Skipping ROCm SDK and PyTorch downloads.
        set SKIP_DOWNLOADS=1
    )
)

if %SKIP_DOWNLOADS% EQU 0 (
    REM Step 1: Install ROCm SDK
    echo Step 1: Installing ROCm SDK components...
    pip install --no-cache-dir ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_core-0.1.dev0-py3-none-win_amd64.whl ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_devel-0.1.dev0-py3-none-win_amd64.whl ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm_sdk_libraries_custom-0.1.dev0-py3-none-win_amd64.whl ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/rocm-0.1.dev0.tar.gz

    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo ERROR: Failed to install ROCm SDK components!
        pause
        exit /b 1
    )

    echo.
    echo Step 2: Installing PyTorch, torchvision, and torchaudio for ROCm...
    pip install --no-cache-dir ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/torch-2.9.0+rocmsdk20251116-cp312-cp312-win_amd64.whl ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/torchaudio-2.9.0+rocmsdk20251116-cp312-cp312-win_amd64.whl ^
        https://repo.radeon.com/rocm/windows/rocm-rel-7.1.1/torchvision-0.24.0+rocmsdk20251116-cp312-cp312-win_amd64.whl

    if %ERRORLEVEL% NEQ 0 (
        echo.
        echo ERROR: Failed to install PyTorch for ROCm!
        pause
        exit /b 1
    )
) else (
    echo.
    echo Skipping Steps 1-2: ROCm SDK and PyTorch already installed.
)

echo.
echo Step 3: Installing base dependencies...
echo Checking and installing missing packages...

REM Check and install each dependency individually
REM Note: Using flexible versions for Python 3.12 compatibility

python -c "import numpy" 2>nul || (
    echo - Installing numpy...
    pip install "numpy>=1.24.0" --quiet
)

python -c "import cv2" 2>nul || (
    echo - Installing opencv-python...
    pip install opencv-python --quiet
)

python -c "import skimage" 2>nul || (
    echo - Installing scikit-image...
    pip install scikit-image --quiet
)

python -c "import tkinter" 2>nul || (
    echo - Installing tk...
    pip install tk --quiet 2>nul || echo   Warning: tk install failed, tkinter might be built-in
)

python -c "import PIL" 2>nul || (
    echo - Installing pillow...
    pip install pillow --quiet
)

python -c "import onnx" 2>nul || (
    echo - Installing onnx...
    pip install onnx --quiet
)

python -c "import google.protobuf" 2>nul || (
    echo - Installing protobuf...
    pip install protobuf --quiet
)

python -c "import tqdm" 2>nul || (
    echo - Installing tqdm...
    pip install tqdm --quiet
)

python -c "import ftfy" 2>nul || (
    echo - Installing ftfy...
    pip install ftfy --quiet
)

python -c "import regex" 2>nul || (
    echo - Installing regex...
    pip install regex --quiet
)

echo All base dependencies checked!

echo.
echo Step 4: Installing Rope in editable mode...
uv pip install -e . --no-deps

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Failed to install Rope package!
    pause
    exit /b 1
)

echo.
echo Step 5: Installing ONNX Runtime with DirectML (AMD GPU support for Windows)...
echo Note: DirectML provides GPU acceleration for AMD GPUs on Windows
echo.

REM First, uninstall any existing onnxruntime to avoid conflicts
echo Removing any existing ONNX Runtime installations...
pip uninstall -y onnxruntime onnxruntime-directml >> %LOGFILE% 2>&1

echo Installing onnxruntime-directml...
pip install onnxruntime-directml >> %LOGFILE% 2>&1

REM Check if DirectML was installed by trying to import it
python -c "import onnxruntime; assert 'DmlExecutionProvider' in onnxruntime.get_available_providers()" 2>nul

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ ONNX Runtime with DirectML installed successfully!
    echo GPU acceleration enabled via DirectML.
    echo.
    goto VERIFY_INSTALL
)

REM DirectML not found, try CPU version
echo.
echo WARNING: DirectML not available
echo See %LOGFILE% for details.
echo Trying standard ONNX Runtime (CPU only)...
echo.

pip install onnxruntime >> %LOGFILE% 2>&1

python -c "import onnxruntime" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ==========================================
    echo ERROR: Failed to install any version of ONNX Runtime!
    echo ==========================================
    echo Rope will not work without ONNX Runtime.
    echo.
    echo Please check:
    echo 1. Internet connection is working
    echo 2. pip is up to date: python -m pip install --upgrade pip
    echo 3. No firewall blocking pip
    echo.
    echo Full error log saved to: %LOGFILE%
    echo.
    pause
    exit /b 1
)

echo.
echo ✓ Standard ONNX Runtime installed successfully (CPU only)
echo WARNING: GPU acceleration will not be available
echo.

:VERIFY_INSTALL

echo.
echo ==========================================
echo Verifying Installation...
echo ==========================================
echo.
echo Checking required modules...
python -c "import cv2, torch, numpy, onnx" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: Some core dependencies are missing!
    echo Please check the error messages above.
    echo.
    echo You may need to manually install missing packages:
    echo   pip install opencv-python numpy onnx
    echo.
    pause
    exit /b 1
)

echo All core modules found!
echo.
echo Checking PyTorch ROCm...
python -c "import torch; print(f'ROCm available: {torch.cuda.is_available()}'); print(f'Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"CPU\"}')"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo WARNING: PyTorch verification failed!
    echo ROCm may not be configured correctly.
    echo.
)

echo.
echo ==========================================
echo Installation completed!
echo ==========================================
echo.
echo You can now run Rope with: Rope-ROCm.bat
echo.

pause
