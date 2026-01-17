<#
.SYNOPSIS
    SSH Key & Git Environment Setup Script (IEX/One-liner Compatible)
.DESCRIPTION
    管理者権限の自動昇格（Tempファイル経由）を行い、
    SSH鍵生成、Git/GitHub CLIインストール、初期設定を一括で行います。
#>

# ==========================================
# メインロジック（実行したい処理の中身）
# ここに以前のスクリプトの内容を文字列として定義します
# ==========================================
$ScriptContent = @'
    # --- 管理者権限で実行される内部ブロック ---

    # エラーハンドリング設定
    $ErrorActionPreference = "Stop"
    
    # 文字化け防止
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8

    # === 関数定義 ===

    # ヘルパー関数: ユーザー確認
    function Get-UserConfirmation {
        param([string]$Message)
        while ($true) {
            Write-Host "$Message (y/n): " -NoNewline -ForegroundColor Yellow
            $response = Read-Host
            if ($response -match '^[yY]$') { return $true }
            elseif ($response -match '^[nN]$') { return $false }
        }
    }

    # ヘルパー関数: PATHの手動追加 (セッション即時反映用)
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
        $hostname = $env:COMPUTERNAME
        Write-Host "ホスト名: $hostname" -ForegroundColor Gray

        # ----------------------------------
        # 1. SSH鍵の作成
        # ----------------------------------
        Write-Host "`n[1/6] SSH鍵の作成" -ForegroundColor Cyan
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
            # Windows標準のssh-keygenを使用
            ssh-keygen -t ed25519 -C $hostname -f $keyPath -N '""'
            if ($LASTEXITCODE -ne 0) { throw "SSH鍵の生成に失敗しました。" }
            Write-Host "SSH鍵を生成しました。" -ForegroundColor Green
        } else {
            Write-Host "既存のSSH鍵を使用します。" -ForegroundColor Green
        }

        # ----------------------------------
        # 2. Gitのインストール
        # ----------------------------------
        Write-Host "`n[2/6] Gitのインストール確認" -ForegroundColor Cyan
        
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Host "Gitをインストール中 (winget)..." -ForegroundColor Yellow
            winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements
            
            # インストール直後はPATHが反映されないため手動追加
            Ensure-Path "$env:ProgramFiles\Git\cmd" "Git"
            Start-Sleep -Seconds 1
            
            if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
                throw "Gitのインストールに失敗したか、PATHが見つかりません。"
            }
            Write-Host "Gitをインストールしました。" -ForegroundColor Green
        } else {
            Write-Host "Gitは既にインストール済みです。" -ForegroundColor Green
        }

        # ----------------------------------
        # 3. GitHub CLIのインストール
        # ----------------------------------
        Write-Host "`n[3/6] GitHub CLIのインストール確認" -ForegroundColor Cyan
        
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "GitHub CLIをインストール中 (winget)..." -ForegroundColor Yellow
            winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
            
            # PATH手動追加
            Ensure-Path "$env:ProgramFiles\GitHub CLI" "GitHub CLI"
            Start-Sleep -Seconds 1

            if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
                throw "GitHub CLIのインストールに失敗しました。"
            }
            Write-Host "GitHub CLIをインストールしました。" -ForegroundColor Green
        } else {
            Write-Host "GitHub CLIは既にインストール済みです。" -ForegroundColor Green
        }

        # ----------------------------------
        # 4. GitHub CLI認証 & 公開鍵登録
        # ----------------------------------
        Write-Host "`n[4/6] GitHub認証とSSH鍵登録" -ForegroundColor Cyan
        
        # 一旦ログアウトを試みる（クリーンな状態にするため）
        $null = gh auth logout --hostname github.com 2>&1

        Write-Host "GitHubにログインします。" -ForegroundColor Yellow
        Write-Host "これからブラウザが開きます。表示されるコードを貼り付けてください。" -ForegroundColor Yellow
        Write-Host "コードは自動的にクリップボードにコピーされます。" -ForegroundColor Yellow
        Write-Host "準備ができたらEnterキーを押してください..." -NoNewline
        $null = Read-Host

        # ログイン実行
        gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --clipboard --scopes "admin:public_key"
        
        if ($LASTEXITCODE -ne 0) { throw "ログイン処理がキャンセルまたは失敗しました。" }

        # 認証完了待ち
        Write-Host "認証状態を確認中..." -ForegroundColor Gray
        $retries = 0
        while ($retries -lt 10) {
            if (gh auth status 2>&1 | Select-String "Logged in") { break }
            Start-Sleep -Seconds 2
            $retries++
        }

        # 公開鍵登録
        Write-Host "SSH公開鍵をGitHubに登録中..." -ForegroundColor Yellow
        if (-not (Test-Path $pubKeyPath)) { throw "公開鍵が見つかりません: $pubKeyPath" }
        
        $pubKeyContent = Get-Content $pubKeyPath -Raw
        $uploadResult = $pubKeyContent | gh ssh-key add - --title "$hostname-$(Get-Date -Format 'yyyyMMdd')" --type authentication 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SSH公開鍵を登録しました。" -ForegroundColor Green
        } elseif ($uploadResult -match "already exists") {
            Write-Host "この鍵は既に登録済みです。" -ForegroundColor Green
        } else {
            Write-Host "鍵登録警告: $uploadResult" -ForegroundColor Yellow
        }

        # ----------------------------------
        # 5. リポジトリのクローン
        # ----------------------------------
        Write-Host "`n[5/6] プロジェクトのセットアップ" -ForegroundColor Cyan
        
        $projectsPath = Join-Path $env:USERPROFILE "projects"
        if (-not (Test-Path $projectsPath)) { New-Item -ItemType Directory -Path $projectsPath -Force | Out-Null }
        
        Set-Location $projectsPath
        
        $repoUrl = "git@github.com:EBP-Japan/ebp-whisper.git"
        $repoName = "ebp-whisper"
        $repoPath = Join-Path $projectsPath $repoName

        if (Test-Path $repoPath) {
            Write-Host "リポジトリフォルダが既に存在します: $repoPath" -ForegroundColor Yellow
            if (Get-UserConfirmation "削除して再クローンしますか？") {
                Remove-Item $repoPath -Recurse -Force
                git clone $repoUrl
            }
        } else {
            Write-Host "リポジトリをクローン中..." -ForegroundColor Yellow
            git clone $repoUrl
        }

        if (-not (Test-Path $repoPath)) { throw "リポジトリの準備に失敗しました。" }
        Set-Location $repoPath

        # ----------------------------------
        # 6. ブランチチェックアウト
        # ----------------------------------
        Write-Host "`n[6/6] ブランチの選択" -ForegroundColor Cyan
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
# 権限昇格ラッパー (WslGit方式)
# ==========================================

# 現在の権限チェック (Administratorグループに属しているか)
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

if ($isAdmin) {
    # 既に管理者の場合は、定義したコンテンツをそのまま実行
    Invoke-Expression $ScriptContent
} else {
    Write-Host "管理者権限が必要です。権限昇格を準備しています..." -ForegroundColor Yellow
    
    # ユニークな一時ファイル名を生成
    $rand = [Guid]::NewGuid().Guid
    $TempScript = Join-Path $env:TEMP "Setup-SSH-Elevated-$rand.ps1"
    
    # スクリプトコンテンツを一時ファイルに保存 (BOM付きUTF8推奨)
    Set-Content -Path $TempScript -Value $ScriptContent -Encoding UTF8
    
    if (-not (Test-Path $TempScript)) {
        Write-Host "一時ファイルの作成に失敗しました。" -ForegroundColor Red
        exit 1
    }

    # 管理者として新しいウィンドウで一時ファイルを実行
    # -Wait: 終了を待つ
    try {
        Start-Process -FilePath "powershell.exe" `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TempScript`"" `
            -Verb RunAs `
            -Wait
    } catch {
        Write-Host "管理者権限への昇格がキャンセルされました。" -ForegroundColor Red
    }
    
    # 実行後、一時ファイルを削除
    if (Test-Path $TempScript) {
        Remove-Item $TempScript -Force -ErrorAction SilentlyContinue
    }
}
