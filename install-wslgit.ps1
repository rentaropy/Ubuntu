# ======================================
# wslgit Automated Installation Script
# (Extract directly to %HOMEPATH%)
# ======================================

# 0. Check for Administrator privileges
#    If not running as Administrator, relaunch with elevation
$isAdmin = ([Security.Principal.WindowsPrincipal]
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Not running as Administrator. Elevating via cmd.exe..."

    $tmp = Join-Path $env:TEMP ("elevate_" + [guid]::NewGuid() + ".cmd")

    @"
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command `
  `"irm https://raw.githubusercontent.com/rentaropy/Ubuntu/refs/heads/main/install-wslgit.ps1 | iex`"
"@ | Set-Content -Encoding ASCII $tmp

    Start-Process cmd.exe `
        -ArgumentList "/c `"$tmp`"" `
        -Verb RunAs `
        -Wait

    Remove-Item $tmp -Force
    exit
}

# ---- elevated execution continues here ----
Write-Host "Running with Administrator privileges"

# Variables
$HomePath   = $env:HOMEPATH
$ZipPath    = Join-Path $HomePath "wslgit.zip"
$WslgitDir  = Join-Path $HomePath "wslgit"

# 1. Retrieve the latest wslgit release information
Write-Host "Fetching latest wslgit release information..."

$Release = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/andy-5/wslgit/releases/latest" `
    -Headers @{ "User-Agent" = "PowerShell" }

$Asset = $Release.assets | Where-Object { $_.name -eq "wslgit.zip" }

if (-not $Asset) {
    Write-Error "wslgit.zip asset not found in the latest release."
    exit 1
}

# Download wslgit.zip
Write-Host "Downloading wslgit.zip..."
Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ZipPath

# 2. Extract ZIP directly into %HOMEPATH%
Write-Host "Extracting wslgit.zip directly into %HOMEPATH%..."

if (Test-Path $WslgitDir) {
    Write-Host "Existing wslgit directory found. Removing..."
    Remove-Item $WslgitDir -Recurse -Force
}

Expand-Archive -Path $ZipPath -DestinationPath $HomePath -Force

# 3. Remove the ZIP file
Write-Host "Removing ZIP file..."
Remove-Item $ZipPath -Force

# 4. Run install.bat with Administrator privileges
$InstallBat = Join-Path $WslgitDir "install.bat"

if (-not (Test-Path $InstallBat)) {
    Write-Error "install.bat not found at expected path: $InstallBat"
    exit 1
}

Write-Host "Running install.bat with Administrator privileges..."
Start-Process `
    -FilePath $InstallBat `
    -WorkingDirectory $WslgitDir `
    -Verb RunAs `
    -Wait

Write-Host "wslgit installation completed successfully."


