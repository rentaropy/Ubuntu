# ======================================
# wslgit Automated Installation Script
# (Improved with proper elevation handling)
# ======================================

& {
    $psv = (Get-Host).Version.Major
    
    # Language Mode check
    if ($ExecutionContext.SessionState.LanguageMode.value__ -ne 0) {
        Write-Host "PowerShell is not running in Full Language Mode." -ForegroundColor Red
        return
    }

    # .NET check
    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies()
        [void][System.Math]::Sqrt(144)
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "PowerShell failed to load .NET command." -ForegroundColor Red
        return
    }

    # Check if running as Administrator
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    
    if (-not $isAdmin) {
        Write-Host "Not running as Administrator. Elevating..." -ForegroundColor Yellow
        
        # Generate unique identifier
        $rand = [Guid]::NewGuid().Guid
        
        # Save current script to temp file
        $ScriptContent = @'
# ---- Elevated execution ----
Write-Host "Running with Administrator privileges" -ForegroundColor Green

$HomePath   = $env:HOMEPATH
$ZipPath    = Join-Path $HomePath "wslgit.zip"
$WslgitDir  = Join-Path $HomePath "wslgit"

try {
    # 1. Fetch latest release
    Write-Host "Fetching latest wslgit release..."
    $Release = Invoke-RestMethod `
        -Uri "https://api.github.com/repos/andy-5/wslgit/releases/latest" `
        -Headers @{ "User-Agent" = "PowerShell" }
    
    $Asset = $Release.assets | Where-Object { $_.name -eq "wslgit.zip" }
    if (-not $Asset) {
        throw "wslgit.zip asset not found in the latest release."
    }

    # 2. Download
    Write-Host "Downloading wslgit.zip..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $ZipPath

    # 3. Extract
    Write-Host "Extracting to $HomePath..."
    if (Test-Path $WslgitDir) {
        Write-Host "Removing existing wslgit directory..."
        Remove-Item $WslgitDir -Recurse -Force
    }
    Expand-Archive -Path $ZipPath -DestinationPath $HomePath -Force

    # 4. Cleanup ZIP
    Write-Host "Cleaning up..."
    Remove-Item $ZipPath -Force

    # 5. Run install.bat
    $InstallBat = Join-Path $WslgitDir "install.bat"
    if (-not (Test-Path $InstallBat)) {
        throw "install.bat not found at: $InstallBat"
    }

    Write-Host "Running install.bat..."
    $process = Start-Process `
        -FilePath "cmd.exe" `
        -ArgumentList "/c `"$InstallBat`"" `
        -WorkingDirectory $WslgitDir `
        -Wait `
        -PassThru `
        -NoNewWindow

    if ($process.ExitCode -eq 0) {
        Write-Host "Installation completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "install.bat exited with code: $($process.ExitCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Installation failed." -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'@
        
        # Save to temp file
        $TempScript = Join-Path $env:TEMP "wslgit_install_$rand.ps1"
        Set-Content -Path $TempScript -Value $ScriptContent -Encoding UTF8
        
        if (-not (Test-Path $TempScript)) {
            Write-Host "Failed to create temporary script file!" -ForegroundColor Red
            return
        }

        # Execute with elevation via cmd.exe (MAS style)
        $env:ComSpec = "$env:SystemRoot\system32\cmd.exe"
        
        if ($psv -lt 3) {
            # PowerShell v2 compatibility
            $p = Start-Process -FilePath $env:ComSpec `
                -ArgumentList "/c powershell -NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" `
                -Verb RunAs `
                -PassThru
            $p.WaitForExit()
        }
        else {
            # PowerShell v3+
            Start-Process -FilePath $env:ComSpec `
                -ArgumentList "/c powershell -NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" `
                -Wait `
                -Verb RunAs
        }
        
        # Cleanup temp file
        Start-Sleep -Seconds 2
        if (Test-Path $TempScript) {
            Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
        }
        
        return
    }

    # If already admin, execute directly (shouldn't happen with irm|iex but kept for safety)
    Write-Host "Already running as Administrator" -ForegroundColor Green
    Write-Host "Please run this script without admin privileges for proper elevation handling." -ForegroundColor Yellow
}
