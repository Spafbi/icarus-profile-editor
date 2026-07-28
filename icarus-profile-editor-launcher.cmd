@echo off
:: Launcher for Icarus Profile Editor - PowerShell Version
:: This script launches the PowerShell version of the editor

:: Check if icarus-profile-editor.ps1 exists
if exist "%~dp0icarus-profile-editor.ps1" (
    goto run_script
)

:: File doesn't exist, download from latest GitHub release
echo Downloading latest icarus-profile-editor.ps1 from GitHub...
curl -s -L "https://api.github.com/repos/Spafbi/icarus-profile-editor/releases/latest" -o "%~dp0latest_release.json"
if %ERRORLEVEL% NEQ 0 (
    echo Failed to download release information from GitHub
    exit /b 1
)

:: Extract the download URL for the ps1 file using PowerShell
powershell -Command ^
$release = Get-Content "%~dp0latest_release.json" | ConvertFrom-Json; ^
$asset = $release.assets | Where-Object { $_.name -eq "icarus-profile-editor.ps1" }; ^
if ($asset) { ^
    $download_url = $asset.browser_download_url; ^
    curl -L -o "%~dp0icarus-profile-editor.ps1" $download_url; ^
    if (%ERRORLEVEL% EQU 0) { ^
        echo Download completed successfully. ^
        del "%~dp0latest_release.json" ^
        goto run_script ^
    } else { ^
        echo Failed to download icarus-profile-editor.ps1 from GitHub ^
        del "%~dp0latest_release.json" ^
        exit /b 1 ^
    } ^
} else { ^
    echo Could not find icarus-profile-editor.ps1 in the latest release assets ^
    del "%~dp0latest_release.json" ^
    exit /b 1 ^
}

:run_script
powershell -ExecutionPolicy Bypass -File "%~dp0icarus-profile-editor.ps1"
exit /b %ERRORLEVEL%
