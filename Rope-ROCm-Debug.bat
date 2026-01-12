@echo off
echo ==========================================
echo Rope Debug Mode - AMD ROCm Support
echo ==========================================
echo.
echo This will run Rope with verbose logging to help diagnose issues.
echo.

REM Check if virtual environment exists
if not exist "venv-rocm\Scripts\activate.bat" (
    echo ERROR: Virtual environment not found!
    echo Please run install-rocm.bat first.
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv-rocm\Scripts\activate.bat

echo.
echo Environment activated successfully!
echo Python version:
python --version

echo.
echo ==========================================
echo DEBUG OPTIONS:
echo ==========================================
echo [1] Verbose logging (-v)
echo [2] Very verbose logging (-vv)
echo [3] Force CPU mode (disable GPU)
echo [4] Force CPU + verbose logging
echo.
choice /C 1234 /N /M "Select option (1-4): "

if errorlevel 4 (
    echo.
    echo Starting Rope with FORCE CPU + VERBOSE LOGGING...
    echo.
    python Rope.py --force-cpu -vv
    goto END
)

if errorlevel 3 (
    echo.
    echo Starting Rope with FORCE CPU mode...
    echo.
    python Rope.py --force-cpu
    goto END
)

if errorlevel 2 (
    echo.
    echo Starting Rope with VERY VERBOSE logging...
    echo.
    python Rope.py -vv
    goto END
)

if errorlevel 1 (
    echo.
    echo Starting Rope with VERBOSE logging...
    echo.
    python Rope.py -v
    goto END
)

:END
echo.
echo.
echo Rope exited with an error.
pause
