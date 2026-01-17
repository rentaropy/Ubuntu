<#
.SYNOPSIS
    SSH Key & Git Environment Setup Script (Windows & WSL Sync Edition - Fix Perms)
.DESCRIPTION
    管理者権限の自動昇格を行い、SSH鍵作成、GitHub認証、WSLへの設定・鍵同期を対話的に行います。
#>

# ==========================================
# メインロジック
# ==========================================
$ScriptContent = @'
    # --- 管理者権限で実行される内部ブロック ---

    $ErrorActionPreference = "Stop"
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # === 関数定義 ===

    function Get-UserConfirmation {
        param([string]$Message)
        while ($true) {
            Write-Host "$Message (y/n): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -match '^[yY]$') { return $true }
            elseif ($response -match '^[nN]$') { return $false }
        }
    }

    function Ensure-Path {
        param([string]$PathToAdd, [string]$ProgramName)
        $pathArray = $env:Path -split ';'
        if ($pathArray -notcontains $PathToAdd) {
            $env:Path = "$PathToAdd;$env:Path"
            Write-Host "セッションPATHに $ProgramName を追加しました。" -ForegroundColor Green
        }
    }

    try {
        Write-Host "`n=== 環境セットアップを開始します ===" -ForegroundColor Cyan
        
        # ----------------------------------
        # 0. 設定値の対話的入力
        # ----------------------------------
        Write-Host "`n[0/7] 設定の入力" -ForegroundColor Cyan
        
        # 1. SSHキー識別子 (入力必須)
        Write-Host "SSHキーの識別子を入力してください。" -ForegroundColor Yellow
        Write-Host "これはキーのコメントとGitHub上のタイトルに使用されます。" -ForegroundColor Gray
        
        $keyIdentifier = ""
        while ([string]::IsNullOrWhiteSpace($keyIdentifier)) {
            $keyIdentifier = Read-Host "識別子 (必須)"
            if ([string]::IsNullOrWhiteSpace($keyIdentifier)) {
                Write-Host "エラー: 識別子の入力は必須です。" -ForegroundColor Red
            }
        }
        Write-Host "使用する識別子: $keyIdentifier" -ForegroundColor Green

        # ----------------------------------
        # 1. SSH鍵の作成
        # ----------------------------------
        Write-Host "`n[1/7] SSH鍵の作成" -ForegroundColor Cyan
        $sshDir = Join-Path $env:USERPROFILE ".ssh"
        $keyPath = Join-Path $sshDir "id_ed25519"
        $pubKeyPath = "$keyPath.pub"

        if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }

        if (Test-Path $keyPath) {
            Write-Host "既存のSSH鍵が見つかりました。" -ForegroundColor Yellow
            if (Get-UserConfirmation "既存の鍵を削除して再作成しますか？") {
                Remove-Item $keyPath,$pubKeyPath -Force -ErrorAction SilentlyContinue
            }
        }

        if (-not (Test-Path $keyPath)) {
            Write-Host "SSH鍵を生成中..." -ForegroundColor Yellow
            ssh-keygen -t ed25519 -C "$keyIdentifier" -f $keyPath -N '""'
            if ($LASTEXITCODE -ne 0) { throw "SSH鍵の生成に失敗しました。" }
            Write-Host "SSH鍵を生成しました。" -ForegroundColor Green
        } else {
            Write-Host "既存のSSH鍵を使用します。" -ForegroundColor Green
        }

        # ----------------------------------
        # 2. Gitのインストール
        # ----------------------------------
        Write-Host "`n[2/7] Gitのインストール確認" -ForegroundColor Cyan
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Gitをインストール中..." -ForegroundColor Yellow
            winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements
            Ensure-Path "$env:ProgramFiles\Git\cmd" "Git"
            Start-Sleep -Seconds 1
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Gitの認識に失敗しました。" }
            Write-Host "Gitをインストールしました。" -ForegroundColor Green
        } else {
            Write-Host "Gitは既にインストール済みです。" -ForegroundColor Green
        }

        # ----------------------------------
        # 3. GitHub CLIのインストール
        # ----------------------------------
        Write-Host "`n[3/7] GitHub CLIのインストール確認" -ForegroundColor Cyan
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "GitHub CLIをインストール中..." -ForegroundColor Yellow
            winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
            Ensure-Path "$env:ProgramFiles\GitHub CLI" "GitHub CLI"
            Start-Sleep -Seconds 1
            if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw "GitHub CLIの認識に失敗しました。" }
            Write-Host "GitHub CLIをインストールしました。" -ForegroundColor Green
        } else {
            Write-Host "GitHub CLIは既にインストール済みです。" -ForegroundColor Green
        }

        # ----------------------------------
        # 4. GitHub CLI認証 & 公開鍵登録
        # ----------------------------------
        Write-Host "`n[4/7] GitHub認証とSSH鍵登録" -ForegroundColor Cyan
        
        $CurrentErrorAction = $ErrorActionPreference
        $ErrorActionPreference = "Continue"

        gh auth logout --hostname github.com 2>&1 | Out-Null

        Write-Host "GitHubにログインします。" -ForegroundColor Yellow
        Write-Host "ブラウザが開いたらコードを貼り付け、認証を完了させてください。" -ForegroundColor Yellow
        Write-Host "準備ができたらEnterキーを押してください..." -NoNewline
        $null = Read-Host

        gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --clipboard --scopes "admin:public_key"
        
        Write-Host "`nブラウザでの操作完了待ち..." -ForegroundColor Yellow
        Write-Host "完了したら Enter キーを押してください..." -ForegroundColor Yellow
        $null = Read-Host

        $authStatus = gh auth status 2>&1 | Out-String
        
        if ($authStatus -match "Logged in") {
             Write-Host "認証を確認しました。" -ForegroundColor Green
        } else {
             $ErrorActionPreference = $CurrentErrorAction
             Write-Host "認証状態: $authStatus" -ForegroundColor Red
             throw "GitHub認証が完了していません。再度実行してください。"
        }
        
        $ErrorActionPreference = $CurrentErrorAction

        # 公開鍵登録
        Write-Host "SSH公開鍵をGitHubに登録中..." -ForegroundColor Yellow
        if (-not (Test-Path $pubKeyPath)) { throw "公開鍵が見つかりません: $pubKeyPath" }
        
        $pubKeyContent = Get-Content $pubKeyPath -Raw
        
        $ErrorActionPreference = "Continue"
        $uploadOutput = $pubKeyContent | gh ssh-key add - --title "$keyIdentifier" --type authentication 2>&1
        $uploadResult = $LASTEXITCODE
        $ErrorActionPreference = $CurrentErrorAction
        
        if ($uploadResult -eq 0) {
            Write-Host "SSH公開鍵を登録しました。" -ForegroundColor Green
        } elseif ($uploadOutput -match "already exists") {
            Write-Host "この鍵は既に登録済みです。" -ForegroundColor Green
        } else {
            Write-Host "鍵登録警告: $uploadOutput" -ForegroundColor Yellow
        }

        # ----------------------------------
        # 5. WSL Safe Directory 設定
        # ----------------------------------
        Write-Host "`n[5/7] WSL Safe Directory設定" -ForegroundColor Cyan
        git config --global --add safe.directory //wsl.localhost/*
        Write-Host "WSL全般のパス(//wsl.localhost/*)をsafe.directoryに追加しました。" -ForegroundColor Green

        # ----------------------------------
        # 6. Git Config (User/Email) 同期
        # ----------------------------------
        Write-Host "`n[6/7] WSLへのGit設定同期 (任意)" -ForegroundColor Cyan
        
        if (Get-UserConfirmation "WindowsのGit設定(User/Email)と認証情報をWSL側にコピーしますか？") {
            try {
                $gitName = git config --global user.name
                $gitEmail = git config --global user.email
                
                if ([string]::IsNullOrWhiteSpace($gitName) -or [string]::IsNullOrWhiteSpace($gitEmail)) {
                    Write-Host "Windows側にGit設定が見つかりません。スキップします。" -ForegroundColor Yellow
                } else {
                    # --- ディストリビューション選択 ---
                    $defaultDistro = "Ubuntu"
                    Write-Host "設定を適用するWSLディストリビューション名を入力してください" -ForegroundColor Yellow
                    $distroInput = Read-Host "ディストリビューション名 (空欄でデフォルト: $defaultDistro)"
                    
                    $targetDistro = if ([string]::IsNullOrWhiteSpace($distroInput)) { $defaultDistro } else { $distroInput }

                    Write-Host "WSL ($targetDistro) に設定を適用中..." -ForegroundColor Yellow
                    
                    # -d オプションで指定したディストリビューションで実行
                    wsl -d $targetDistro git config --global user.name "$gitName"
                    wsl -d $targetDistro git config --global user.email "$gitEmail"
                    
                    # Windows側のCredential ManagerをWSLで使えるように設定
                    $credHelperPath = "/mnt/c/Program\ Files/Git/mingw64/libexec/git-core/git-credential-manager.exe"
                    wsl -d $targetDistro git config --global credential.helper "$credHelperPath"
                    
                    Write-Host "Git設定とCredential HelperをWSL ($targetDistro) に同期しました。" -ForegroundColor Green
                }
            } catch {
                Write-Host "Git設定の同期に失敗しました: $_" -ForegroundColor Red
            }
        } else {
            Write-Host "Git設定の同期をスキップしました。" -ForegroundColor Gray
        }

        # ----------------------------------
        # 7. SSH鍵のWSL同期
        # ----------------------------------
        Write-Host "`n[7/7] SSH鍵のWSL同期 (任意)" -ForegroundColor Cyan

        if (Get-UserConfirmation "SSH鍵(.ssh)をWindowsからWSLに同期しますか？") {
            
            # --- パス入力 (デフォルト値あり) ---
            $winDefault = Join-Path $env:USERPROFILE ".ssh"
            # 要求されたデフォルトパス
            $wslDefault = "\\wsl.localhost\Ubuntu\home\ubuntu\.ssh"

            Write-Host "パスを確認してください (空欄でデフォルト値を使用)" -ForegroundColor Yellow
            
            $srcPath = Read-Host "コピー元 (Windows) [$winDefault]"
            if ([string]::IsNullOrWhiteSpace($srcPath)) { $srcPath = $winDefault }

            $destPath = Read-Host "コピー先 (WSL)     [$wslDefault]"
            if ([string]::IsNullOrWhiteSpace($destPath)) { $destPath = $wslDefault }

            if (-not (Test-Path $srcPath)) {
                Write-Host "コピー元が見つかりません: $srcPath" -ForegroundColor Red
            } else {
                if (-not (Test-Path $destPath)) {
                    Write-Host "コピー先ディレクトリを作成中..." -ForegroundColor Gray
                    New-Item -ItemType Directory -Path $destPath -Force | Out-Null
                }

                Write-Host "ファイルをコピー中..." -ForegroundColor Yellow
                Copy-Item "$srcPath\*" -Destination $destPath -Recurse -Force

                Write-Host "WSL側で権限(chmod)を修正中..." -ForegroundColor Yellow
                
                # --- 権限修正ロジックの強化 ---
                # 1. Distro名の抽出
                $distroName = "Ubuntu" 
                if ($destPath -match '^\\\\wsl\.localhost\\([^\\]+)\\') {
                    $distroName = $matches[1]
                }
                
                try {
                    # 2. Windowsパス($destPath)をWSL内部のLinuxパスに変換
                    # これにより、ユーザーがどのパスを指定しても正確なターゲットを取得
                    $linuxPath = wsl -d $distroName wslpath -u "$destPath"
                    $linuxPath = $linuxPath.Trim()
                    
                    Write-Host "ターゲットDistro: $distroName" -ForegroundColor Gray
                    Write-Host "Linuxパス: $linuxPath" -ForegroundColor Gray

                    # 3. 具体的なファイルに対してchmodを実行 (再帰的findよりも確実)
                    # ディレクトリ権限
                    wsl -d $distroName chmod 700 "$linuxPath"
                    
                    # 秘密鍵権限 (600: 自分だけ読み書き可能)
                    # *ワイルドカードを使うとknown_hostsなども巻き込むため、主要な鍵名を指定
                    wsl -d $distroName chmod 600 "$linuxPath/id_ed25519"
                    wsl -d $distroName chmod 600 "$linuxPath/id_rsa" 2>$null # 存在すれば
                    
                    # 公開鍵・known_hosts権限 (644: 自分は読み書き、他人は読むだけ)
                    wsl -d $distroName chmod 644 "$linuxPath/id_ed25519.pub"
                    wsl -d $distroName chmod 644 "$linuxPath/known_hosts"
                    wsl -d $distroName chmod 644 "$linuxPath/config" 2>$null
                    
                    Write-Host "SSH鍵の権限を修正しました (600)。" -ForegroundColor Green
                } catch {
                    Write-Host "権限修正中にエラーが発生しました: $_" -ForegroundColor Red
                    Write-Host "手動で 'chmod 600 ~/.ssh/id_ed25519' を実行してください。" -ForegroundColor Yellow
                }
            }
        } else {
            Write-Host "SSH鍵の同期をスキップしました。" -ForegroundColor Gray
        }

        Write-Host "`n=== すべての処理が完了しました ===" -ForegroundColor Green
        Write-Host "Enterキーを押して終了してください..."
        $null = Read-Host

    } catch {
        Write-Host "`n[エラー] 処理中にエラーが発生しました:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "Enterキーを押して終了してください..."
        $null = Read-Host
        exit 1
    }
'@

# ==========================================
# 権限昇格ラッパー
# ==========================================
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if ($isAdmin) {
    Invoke-Expression $ScriptContent
} else {
    Write-Host "管理者権限が必要です。権限昇格を準備しています..." -ForegroundColor Yellow
    $rand = [Guid]::NewGuid().Guid
    $TempScript = Join-Path $env:TEMP "Setup-SSH-Elevated-$rand.ps1"
    Set-Content -Path $TempScript -Value $ScriptContent -Encoding UTF8
    
    try {
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" `
            -Verb RunAs -Wait
    } catch {
        Write-Host "管理者権限への昇格が失敗しました。" -ForegroundColor Red
    }
    
    if (Test-Path $TempScript) { Remove-Item $TempScript -Force -ErrorAction SilentlyContinue }
}
