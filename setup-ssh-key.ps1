<#
.SYNOPSIS
    SSH Key & Git Environment Setup Script (IEX/One-liner Compatible)
.DESCRIPTION
    管理者権限の自動昇格を行い、SSH鍵識別子(必須)、リポジトリURL(任意)、保存先パス(任意)を対話的に決定して環境構築を行います。
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
        # 5. リポジトリのクローン (任意入力)
        # ----------------------------------
        Write-Host "`n[5/7] プロジェクトのセットアップ" -ForegroundColor Cyan
        
        Write-Host "クローンするリポジトリのURLを入力してください" -ForegroundColor Yellow
        Write-Host "(空欄のままEnterを押すと、クローンを行わずに終了します)" -ForegroundColor Gray
        $repoUrl = Read-Host "URL"

        # 変数初期化（最終表示用）
        $finalRepoPath = ""

        # URLが入力された場合のみ実行
        if (-not [string]::IsNullOrWhiteSpace($repoUrl)) {
            
            # --- 保存先フォルダの選択 ---
            $defaultParentPath = Join-Path $env:USERPROFILE "projects"
            
            Write-Host "`n保存先の親フォルダを入力してください。" -ForegroundColor Yellow
            $parentPathInput = Read-Host "パス (空白でデフォルト: $defaultParentPath)"
            
            if ([string]::IsNullOrWhiteSpace($parentPathInput)) {
                $projectsPath = $defaultParentPath
            } else {
                # 環境変数の展開（%USERPROFILE%などに対応）
                $projectsPath = [System.Environment]::ExpandEnvironmentVariables($parentPathInput)
            }

            if (-not (Test-Path $projectsPath)) {
                New-Item -ItemType Directory -Path $projectsPath -Force | Out-Null
                Write-Host "保存先フォルダを作成しました: $projectsPath" -ForegroundColor Green
            }
            Set-Location $projectsPath

            # URLからフォルダ名を抽出
            $repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
            $repoPath = Join-Path $projectsPath $repoName
            $finalRepoPath = $repoPath # 最終表示用に保持

            Write-Host "ターゲット: $repoPath" -ForegroundColor Gray

            if (Test-Path $repoPath) {
                Write-Host "フォルダ '$repoName' が既に存在します。" -ForegroundColor Yellow
                if (Get-UserConfirmation "削除して再クローンしますか？") {
                    Remove-Item $repoPath -Recurse -Force
                    Write-Host "クローン中: $repoUrl" -ForegroundColor Yellow
                    git clone $repoUrl
                } else {
                    Write-Host "既存のフォルダを使用します。" -ForegroundColor Green
                }
            } else {
                Write-Host "クローン中: $repoUrl" -ForegroundColor Yellow
                git clone $repoUrl
            }
            
            if (-not (Test-Path $repoPath)) { 
                Write-Host "リポジトリが見つからないため、ブランチ切り替えをスキップします。" -ForegroundColor Yellow 
            } else {
                Set-Location $repoPath

                # ----------------------------------
                # 6. ブランチチェックアウト
                # ----------------------------------
                Write-Host "`n[6/7] ブランチの選択" -ForegroundColor Cyan
                git fetch --all | Out-Null
                
                while ($true) {
                    $branchName = Read-Host "チェックアウトするブランチ名を入力してください"
                    if ([string]::IsNullOrWhiteSpace($branchName)) { continue }

                    if (git branch -r | Select-String "/$branchName$") {
                        git checkout $branchName
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "ブランチ '$branchName' に切り替えました。" -ForegroundColor Green
                            break
                        }
                    } else {
                        Write-Host "リモートブランチが見つかりません。" -ForegroundColor Red
                    }
                }
            }
        } else {
            Write-Host "URLが入力されなかったため、リポジトリのセットアップをスキップします。" -ForegroundColor Green
        }

        # ----------------------------------
        # 7. WSL Safe Directory 設定 (追加)
        # ----------------------------------
        Write-Host "`n[7/7] WSL Safe Directory設定" -ForegroundColor Cyan
        git config --global --add safe.directory //wsl.localhost/*
        Write-Host "WSLパスをsafe.directoryに追加しました。" -ForegroundColor Green

        Write-Host "`n=== すべての処理が完了しました ===" -ForegroundColor Green
        
        # --- 最終結果の表示 ---
        if (-not [string]::IsNullOrWhiteSpace($finalRepoPath) -and (Test-Path $finalRepoPath)) {
            Write-Host "`n[INFO] 以下のディレクトリにクローンされました:" -ForegroundColor Cyan
            Write-Host "--------------------------------------------------" -ForegroundColor Gray
            Write-Host $finalRepoPath -ForegroundColor White
            Write-Host "--------------------------------------------------" -ForegroundColor Gray
        }

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
