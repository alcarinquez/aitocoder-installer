@echo off
setlocal enabledelayedexpansion

echo ========================================
echo AitoCoder Windows Installer
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo Warning: Not running as administrator. Some operations may fail.
    echo Consider running as administrator for system-wide installation.
    echo.
)

REM Set installation directory
set "INSTALL_DIR=%PROGRAMFILES%\AitoCoder"
set "SCRIPT_NAME=aitocoder.chat"

REM Check if installation directory exists
if exist "%INSTALL_DIR%" (
    echo Installation directory already exists: %INSTALL_DIR%
    set /p "OVERWRITE=Do you want to overwrite the existing installation? (y/N): "
    if /i not "!OVERWRITE!"=="y" (
        echo Installation cancelled.
        pause
        exit /b 1
    )
    echo Removing existing installation...
    rmdir /s /q "%INSTALL_DIR%" 2>nul
)

REM Create installation directory
echo Creating installation directory: %INSTALL_DIR%
mkdir "%INSTALL_DIR%" 2>nul
if not exist "%INSTALL_DIR%" (
    echo Error: Failed to create installation directory.
    echo Try running as administrator or choose a different location.
    pause
    exit /b 1
)

REM Check if aitocoder_win.zip exists
if not exist "aitocoder_win.zip" (
    echo Error: aitocoder_win.zip not found in current directory.
    echo Please ensure the zip file is in the same directory as this installer.
    pause
    exit /b 1
)

REM Extract the conda environment
echo Extracting conda environment...
powershell -Command "Expand-Archive -Path 'aitocoder_win.zip' -DestinationPath '%INSTALL_DIR%' -Force"
if %errorLevel% neq 0 (
    echo Error: Failed to extract aitocoder_win.zip
    pause
    exit /b 1
)

REM Find the Scripts directory with aitocoder.chat.exe
echo Checking for aitocoder.chat.exe...
if exist "%INSTALL_DIR%\Scripts\aitocoder.chat.exe" (
    echo Found aitocoder.chat.exe at: %INSTALL_DIR%\Scripts\aitocoder.chat.exe
) else (
    echo Looking for aitocoder.chat.exe in subdirectories...
    set "FOUND=0"
    for /d %%D in ("%INSTALL_DIR%\*") do (
        if exist "%%D\Scripts\aitocoder.chat.exe" (
            echo Found aitocoder.chat.exe at: %%D\Scripts\aitocoder.chat.exe
            echo Moving contents to main directory...
            robocopy "%%D" "%INSTALL_DIR%" /E /MOVE /NP >nul
            set "FOUND=1"
            goto :found_exe
        )
    )
    :found_exe
    if "!FOUND!"=="0" (
        echo Error: Could not find aitocoder.chat.exe in Scripts directory.
        echo Contents of %INSTALL_DIR%:
        dir "%INSTALL_DIR%" /b
        pause
        exit /b 1
    )
)

REM Run conda-unpack if available
echo Configuring environment...
if exist "%INSTALL_DIR%\Scripts\conda-unpack.exe" (
    "%INSTALL_DIR%\Scripts\conda-unpack.exe" 2>nul || echo Warning: conda-unpack failed, but continuing...
) else (
    echo conda-unpack.exe not found, skipping...
)

REM Add Scripts directory to system PATH
set "SCRIPTS_DIR=%INSTALL_DIR%\Scripts"
echo Adding AitoCoder Scripts directory to system PATH...
for /f "tokens=2*" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "SYSTEM_PATH=%%B"

REM Remove any existing AitoCoder entries from PATH first (both main and Scripts directories)
echo Cleaning up any existing AitoCoder PATH entries...
set "SYSTEM_PATH=!SYSTEM_PATH:;%INSTALL_DIR%\Scripts;=;!"
set "SYSTEM_PATH=!SYSTEM_PATH:;%INSTALL_DIR%;=;!"
set "SYSTEM_PATH=!SYSTEM_PATH:;%INSTALL_DIR%\Scripts=!"
set "SYSTEM_PATH=!SYSTEM_PATH:;%INSTALL_DIR%=!"
set "SYSTEM_PATH=!SYSTEM_PATH:%INSTALL_DIR%\Scripts;=!"
set "SYSTEM_PATH=!SYSTEM_PATH:%INSTALL_DIR%;=!"
REM Clean up any double semicolons that might have been created
set "SYSTEM_PATH=!SYSTEM_PATH:;;=;!"
if "!SYSTEM_PATH!"=="%INSTALL_DIR%\Scripts" set "SYSTEM_PATH="
if "!SYSTEM_PATH!"=="%INSTALL_DIR%" set "SYSTEM_PATH="

REM Add Scripts directory to PATH
echo Adding %SCRIPTS_DIR% to system PATH...
if "!SYSTEM_PATH!"=="" (
    set "NEW_PATH=%SCRIPTS_DIR%"
) else (
    set "NEW_PATH=!SYSTEM_PATH!;%SCRIPTS_DIR%"
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul 2>&1
    if %errorLevel% equ 0 (
        echo Successfully added to system PATH.
        REM Broadcast PATH change
        powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'Machine'), 'Machine')" >nul 2>&1
    ) else (
        echo Warning: Failed to add to system PATH. You may need to add manually:
        echo %SCRIPTS_DIR%
    )

REM Test the installation
echo Testing installation...
if exist "%INSTALL_DIR%\Scripts\aitocoder.chat.exe" (
    echo Installation test: SUCCESS - aitocoder.chat.exe found
) else (
    echo Installation test: FAILED - aitocoder.chat.exe not found
    pause
    exit /b 1
)

echo.
echo ========================================
echo Installation completed successfully!
echo ========================================
echo.
echo Installation location: %INSTALL_DIR%
echo.
echo To use AitoCoder:
echo 1. Open a new Command Prompt or PowerShell window
echo 2. Type: %SCRIPT_NAME%
echo.
echo If the command is not recognized, restart your terminal or log out/in.
echo.

pause
