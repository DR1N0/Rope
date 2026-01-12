@echo off
echo ==========================================
echo Rope - AMD ROCm Launcher
echo ==========================================
echo.

REM Check if virtual environment exists
if not exist "venv-rocm\Scripts\activate.bat" (
    echo ERROR: ROCm virtual environment not found!
    echo.
    echo Please run install-rocm.bat first to set up the environment.
    echo.
    pause
    exit /b 1
)

REM Activate virtual environment
echo Activating ROCm virtual environment...
call venv-rocm\Scripts\activate.bat

REM Check if activation was successful
python -c "import sys; sys.exit(0 if sys.version_info[:2] == (3, 12) else 1)" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to activate Python 3.12 environment!
    echo.
    echo Please reinstall using install-rocm.bat
    pause
    exit /b 1
)

echo.
echo Environment activated successfully!
echo Python version:
python --version
echo.

REM Run Rope
echo Starting Rope...
echo.
python Rope.py

REM Keep window open if there's an error
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Rope exited with an error.
    pause
)
