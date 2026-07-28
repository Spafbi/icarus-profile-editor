@echo off
:: Launcher for Icarus Profile Editor - PowerShell Version
:: This script launches the PowerShell version of the editor

:: Check if icarus-profile-editor.ps1 exists
if exist "%~dp0icarus-profile-editor.ps1" (
    goto run_script
)

echo Downloading latest icarus-profile-editor.ps1 from GitHub...

:: Use PowerShell with properly escaped single quotes (known working approach)
powershell -Command "try { $r = Invoke-RestMethod 'https://api.github.com/repos/Spafbi/icarus-profile-editor/releases/latest'; $a = $r.assets | Where-Object { $_.name -eq 'icarus-profile-editor.ps1' }; if ($a) { Invoke-WebRequest -Uri $a.browser_download_url -OutFile '%~dp0icarus-profile-editor.ps1'; Write-Host 'Download completed successfully.'; } else { Write-Host 'Could not find icarus-profile-editor.ps1 in release assets.'; exit 1; } } catch { Write-Host 'Error: $_'; exit 1; }"

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to download icarus-profile-editor.ps1 from GitHub
    exit /b 1
)

:run_script
powershell -ExecutionPolicy Bypass -File "%~dp0icarus-profile-editor.ps1"
exit /b %ERRORLEVEL%
