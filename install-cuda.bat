@echo off
echo ==========================================
echo Rope Installation - NVIDIA CUDA Support
echo ==========================================
echo.

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

echo Installing dependencies with NVIDIA CUDA support...
echo.

REM Install with CUDA dependencies using uv sync
uv sync --extra cuda --index-url https://download.pytorch.org/whl/cu118

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ==========================================
    echo Installation completed successfully!
    echo ==========================================
    echo.
    echo You can now run Rope with: Rope.bat
    echo.
) else (
    echo.
    echo ==========================================
    echo Installation failed!
    echo ==========================================
    echo.
    echo Please check the error messages above.
    echo.
)

pause
