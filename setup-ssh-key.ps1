#Requires -Version 5.1

# 管理者権限チェック関数
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 管理者権限で再実行
if (-not (Test-Administrator)) {
    Write-Host "管理者権限が必要です。管理者権限で再実行します..." -ForegroundColor Yellow
    
    # 現在のスクリプトパスを取得
    $scriptPath = $MyInvocation.MyCommand.Path
    
    # 管理者権限で再実行
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    
    # 現在のプロセスを終了
    exit
}

Write-Host "管理者権限で実行中です。" -ForegroundColor Green

# エラーハンドリングの設定
$ErrorActionPreference = "Stop"

# ヘルパー関数: ユーザー確認
function Get-UserConfirmation {
    param([string]$Message)
    
    while ($true) {
        Write-Host "$Message (y/n): " -NoNewline -ForegroundColor Yellow
        $response = Read-Host
        
        Write-Host "[DEBUG] 入力された値: '$response'" -ForegroundColor Gray
        
        if ($response -eq 'y' -or $response -eq 'Y') {
            return $true
        } elseif ($response -eq 'n' -or $response -eq 'N') {
            return $false
        } else {
            Write-Host "yまたはnを入力してください。" -ForegroundColor Red
        }
    }
}

# ヘルパー関数: パスの存在確認と削除
function Remove-PathIfExists {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        Write-Host "$Description が既に存在します: $Path" -ForegroundColor Yellow
        if (Get-UserConfirmation "削除して再作成しますか?") {
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "$Description を削除しました。" -ForegroundColor Green
            return $true
        } else {
            Write-Host "処理をキャンセルしました。" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# === 根本的修正 ===
# ヘルパー関数: 既知のパスを現在のセッションのPATHに「手動で」追加する
function Ensure-Path {
    param(
        [string]$PathToAdd,
        [string]$ProgramName
    )
    
    Write-Host "PATH確認中: $ProgramName ($PathToAdd)" -ForegroundColor Gray
    
    # 既に現在のセッションのPATHに含まれているか確認 (大文字小文字を区別しない)
    $pathArray = $env:Path -split ';'
    $found = $false
    foreach ($p in $pathArray) {
        if ($p -eq $PathToAdd) {
            $found = $true
            break
        }
    }
    
    if (-not $found) {
        # PATHの先頭に追加 ( ; で結合)
        $env:Path = "$PathToAdd;$env:Path"
        Write-Host "セッションPATHに $ProgramName のパスを追加しました。" -ForegroundColor Green
    } else {
        Write-Host "$ProgramName のパスは既にセッションPATHに存在します。" -ForegroundColor Gray
    }
}
# === 修正ここまで ===


try {
    # 1. ホスト名を取得
    $hostname = $env:COMPUTERNAME
    Write-Host "ホスト名: $hostname" -ForegroundColor Cyan

    # 2. SSH鍵の作成
    Write-Host "`n=== SSH鍵の作成 ===" -ForegroundColor Cyan
    $sshDir = Join-Path $env:USERPROFILE ".ssh"
    $keyPath = Join-Path $sshDir "id_ed25519"
    $pubKeyPath = "$keyPath.pub"

    # .sshディレクトリが存在しない場合は作成
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    # 既存の鍵ファイルをチェック
    if ((Test-Path $keyPath) -or (Test-Path $pubKeyPath)) {
        if (-not (Remove-PathIfExists $keyPath "SSH秘密鍵")) {
            exit 1
        }
        if (Test-Path $pubKeyPath) {
            Remove-Item -Path $pubKeyPath -Force
        }
    }

    # SSH鍵を生成 (winget install の前に実行されるため、標準のOpenSSH Clientに依存)
    Write-Host "SSH鍵を生成中..." -ForegroundColor Yellow
    # 既に C:\Windows\System32\OpenSSH\ssh-keygen.exe がPATHにあるはず
    ssh-keygen -t ed25519 -C $hostname -f $keyPath -N '""'
    
    if ($LASTEXITCODE -ne 0) {
        throw "SSH鍵の生成に失敗しました。WindowsのOpenSSH Clientが有効か確認してください。"
    }
    Write-Host "SSH鍵を生成しました。" -ForegroundColor Green

    # 3. Gitのインストール
    Write-Host "`n=== Gitのインストール確認 ===" -ForegroundColor Cyan
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue

    if (-not $gitInstalled) {
        Write-Host "Gitをインストール中..." -ForegroundColor Yellow

        # winget install 実行
        $installResult = winget install --id Git.Git --silent --accept-source-agreements --accept-package-agreements
        $exitCode = $LASTEXITCODE

        # 正常終了または「既に最新」も成功扱い
        $acceptableCodes = @(0, -1978335212, -1978335189)
        if ($acceptableCodes -notcontains $exitCode) {
            throw "Gitのインストールに失敗しました。（winget 終了コード: $exitCode）"
        }

        if ($exitCode -eq -1978335189) {
            Write-Host "Gitは既に最新バージョンです。" -ForegroundColor Green
        } elseif ($exitCode -eq -1978335212) {
            Write-Host "Gitは既にインストール済みです。" -ForegroundColor Green
        } else {
            Write-Host "Gitをインストールしました。" -ForegroundColor Green
        }

        # === 修正されたアプローチ ===
        # wingetの挙動に依存せず、既知のパスをセッションに「手動で」追加する
        # $env:ProgramFiles は "C:\Program Files"
        Ensure-Path -PathToAdd "$env:ProgramFiles\Git\cmd" -ProgramName "Git"
        Start-Sleep -Seconds 1 # PATHの反映を待つ

        # 再確認
        $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
        if (-not $gitInstalled) {
            Write-Host "PATHを手動で追加しましたがGitが見つかりません。" -ForegroundColor Red
            Write-Host "[DEBUG] 現在のPATH: $env:Path" -ForegroundColor Gray
            throw "Gitのインストール後、PATH認識に失敗しました。"
        }
        Write-Host "Gitコマンドが認識されました。" -ForegroundColor Green

    } else {
        $gitVersion = (git --version) -replace "git version", ""
        Write-Host "Gitは既にインストールされています。バージョン: $gitVersion" -ForegroundColor Green
    }

    # 4. GitHub CLIのインストール
    Write-Host "`n=== GitHub CLIのインストール確認 ===" -ForegroundColor Cyan
    $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
    
    if (-not $ghInstalled) {
        Write-Host "GitHub CLIをインストール中..." -ForegroundColor Yellow
        winget install --id GitHub.cli --silent --accept-source-agreements --accept-package-agreements
        
        # === 修正されたアプローチ ===
        # wingetの挙動に依存せず、既知のパスをセッションに「手動で」追加する
        Ensure-Path -PathToAdd "$env:ProgramFiles\GitHub CLI" -ProgramName "GitHub CLI"
        Start-Sleep -Seconds 1 # PATHの反映を待つ

        # 再度確認
        $ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
        if (-not $ghInstalled) {
            throw "GitHub CLIのインストールに失敗しました。PowerShellを再起動してください。"
        }
        Write-Host "GitHub CLIをインストールしました。" -ForegroundColor Green
    } else {
        Write-Host "GitHub CLIは既にインストールされています。" -ForegroundColor Green
    }

    # 5. GitHub CLIからログアウト
    Write-Host "`n=== GitHub CLIログアウト ===" -ForegroundColor Cyan
    
    # ErrorActionPreferenceを一時的に変更してエラーを捕捉
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    
    $authStatus = gh auth status 2>&1
    $authStatusString = $authStatus | Out-String
    
    if ($authStatusString -match "Logged in" -and $authStatusString -notmatch "not logged into") {
        Write-Host "GitHub CLIからログアウト中..." -ForegroundColor Yellow
        $logoutOutput = gh auth logout --hostname github.com 2>&1
        $logoutResult = $LASTEXITCODE
        
        # ログアウトは成功メッセージもstderrに出力されるため、終了コードで判定
        if ($logoutResult -eq 0) {
            Write-Host "ログアウトしました。" -ForegroundColor Green
        } else {
            Write-Host "警告: ログアウトで予期しない終了コードが返されました: $logoutResult" -ForegroundColor Yellow
            Write-Host "出力: $logoutOutput" -ForegroundColor Gray
        }
    } else {
        Write-Host "ログインしていません。" -ForegroundColor Green
    }
    
    $ErrorActionPreference = $previousErrorActionPreference

    # 6. SSH公開鍵をGitHubに登録
    Write-Host "`n=== GitHubへのSSH公開鍵登録 ===" -ForegroundColor Cyan
    Write-Host "GitHubにログインします..." -ForegroundColor Yellow
    
    try {
        # 公開鍵の内容を読み込む
        Write-Host "[DEBUG] 公開鍵を読み込んでいます: $pubKeyPath" -ForegroundColor Gray
        
        if (-not (Test-Path $pubKeyPath)) {
            throw "公開鍵ファイルが見つかりません: $pubKeyPath"
        }
        
        $publicKey = Get-Content $pubKeyPath -Raw
        Write-Host "[DEBUG] 公開鍵を読み込みました (長さ: $($publicKey.Length) 文字)" -ForegroundColor Gray
        
        # GitHub CLIでログイン (ワンタイムコードをクリップボードにコピー)
        Write-Host "`nブラウザが開きます。表示されるコードを貼り付けてください。" -ForegroundColor Yellow
        Write-Host "コードはクリップボードにコピーされます。" -ForegroundColor Yellow
        
        # ログインプロセスを開始（対話モード）
        Write-Host "[DEBUG] gh auth login を実行しています..." -ForegroundColor Gray
        Write-Host "`n" -NoNewline
        Write-Host "=".PadRight(60, "=") -ForegroundColor Yellow
        Write-Host "これからGitHubへのログインを開始します。" -ForegroundColor Yellow
        Write-Host "ワンタイムコードが自動的にクリップボードにコピーされます。" -ForegroundColor Yellow
        Write-Host "Enterキーを押してブラウザを開き、コードを貼り付けてください。" -ForegroundColor Yellow
        Write-Host "=".PadRight(60, "=") -ForegroundColor Yellow
        Write-Host ""
        
        # gh auth login を対話的に実行（SSH鍵管理のスコープを追加）
        gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key --clipboard --scopes "admin:public_key"
        
        $loginExitCode = $LASTEXITCODE
        
        Write-Host "[DEBUG] gh auth login の終了コード: $loginExitCode" -ForegroundColor Gray
        
        if ($loginExitCode -ne 0) {
            throw "GitHub CLIログインに失敗しました。終了コード: $loginExitCode"
        }
        
        Write-Host "`nGitHubへのログインが完了しました。" -ForegroundColor Green
        
        # 認証状態を確認
        Write-Host "[DEBUG] 認証状態を確認しています..." -ForegroundColor Gray
        $maxRetries = 12
        $retryCount = 0
        $authenticated = $false
        
        while ($retryCount -lt $maxRetries) {
            $previousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            
            $authStatus = gh auth status 2>&1
            $authStatusString = $authStatus | Out-String
            
            $ErrorActionPreference = $previousErrorActionPreference
            
            Write-Host "[DEBUG] 試行 $($retryCount + 1)/$maxRetries - 認証状態: $($authStatusString.Substring(0, [Math]::Min(50, $authStatusString.Length)))..." -ForegroundColor Gray
            
            if ($authStatusString -match "Logged in") {
                $authenticated = $true
                break
            }
            Start-Sleep -Seconds 5
            $retryCount++
        }
        
        if (-not $authenticated) {
            throw "GitHub認証がタイムアウトしました。スクリプトを再実行してください。"
        }
        
        Write-Host "認証に成功しました。" -ForegroundColor Green
        
        # SSH公開鍵を登録
        Write-Host "`nSSH公開鍵を登録中..." -ForegroundColor Yellow
        Write-Host "[DEBUG] gh ssh-key add を実行しています..." -ForegroundColor Gray
        
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        
        $sshKeyOutput = $publicKey | gh ssh-key add - --title $hostname --type authentication 2>&1
        $sshKeyResult = $LASTEXITCODE
        
        $ErrorActionPreference = $previousErrorActionPreference
        
        Write-Host "[DEBUG] SSH鍵登録の結果コード: $sshKeyResult" -ForegroundColor Gray
        Write-Host "[DEBUG] SSH鍵登録の出力: $sshKeyOutput" -ForegroundColor Gray
        
        if ($sshKeyResult -eq 0) {
            Write-Host "SSH公開鍵を登録しました。" -ForegroundColor Green
        } else {
            throw "SSH公開鍵の登録に失敗しました。終了コード: $sshKeyResult, 出力: $sshKeyOutput"
        }
        
    } catch {
        Write-Host "[ERROR] GitHubへのSSH公開鍵登録中にエラーが発生しました" -ForegroundColor Red
        Write-Host "エラーメッセージ: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "エラーの種類: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        Write-Host "発生場所: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Red
        throw
    }

    # 7. ホームディレクトリに移動
    Write-Host "`n=== ホームディレクトリに移動 ===" -ForegroundColor Cyan
    Set-Location $env:USERPROFILE
    Write-Host "現在のディレクトリ: $(Get-Location)" -ForegroundColor Green

    # 7. projectsフォルダを作成
    Write-Host "`n=== projectsフォルダの作成 ===" -ForegroundColor Cyan
    $projectsPath = Join-Path $env:USERPROFILE "projects"
    
    if (-not (Remove-PathIfExists $projectsPath "projectsフォルダ")) {
        exit 1
    }
    
    New-Item -ItemType Directory -Path $projectsPath -Force | Out-Null
    Write-Host "projectsフォルダを作成しました: $projectsPath" -ForegroundColor Green

    # 8. projectsフォルダに移動
    Write-Host "`n=== projectsフォルダに移動 ===" -ForegroundColor Cyan
    Set-Location $projectsPath
    Write-Host "現在のディレクトリ: $(Get-Location)" -ForegroundColor Green

    # 9. リポジトリをクローン
    Write-Host "`n=== リポジトリのクローン ===" -ForegroundColor Cyan
    $repoUrl = "git@github.com:EBP-Japan/ebp-whisper.git"
    $repoName = "ebp-whisper"
    $repoPath = Join-Path $projectsPath $repoName
    
    if (-not (Remove-PathIfExists $repoPath "リポジトリ")) {
        exit 1
    }
    
    Write-Host "リポジトリをクローン中: $repoUrl" -ForegroundColor Yellow
    git clone $repoUrl
    
    if ($LASTEXITCODE -ne 0) {
        throw "リポジトリのクローンに失敗しました。"
    }
    Write-Host "リポジトリをクローンしました。" -ForegroundColor Green
    
    # リポジトリディレクトリに移動
    Set-Location $repoPath
    Write-Host "現在のディレクトリ: $(Get-Location)" -ForegroundColor Green

    # 10. ブランチ名の入力とチェックアウト
    Write-Host "`n=== ブランチのチェックアウト ===" -ForegroundColor Cyan
    
    # リモートブランチの一覧を取得
    git fetch --all | Out-Null
    
    $branchCheckout = $false
    while (-not $branchCheckout) {
        $branchName = Read-Host "`nチェックアウトするブランチ名を入力してください"
        
        if ([string]::IsNullOrWhiteSpace($branchName)) {
            Write-Host "ブランチ名を入力してください。" -ForegroundColor Red
            continue
        }
        
        # ブランチの存在確認
        $branchExists = git branch -a | Where-Object { $_ -match "remotes/origin/$branchName$" }
        
        if ($branchExists) {
            Write-Host "ブランチ '$branchName' にチェックアウト中..." -ForegroundColor Yellow
            git checkout $branchName
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "ブランチ '$branchName' にチェックアウトしました。" -ForegroundColor Green
                $branchCheckout = $true
            } else {
                Write-Host "チェックアウトに失敗しました。再試行してください。" -ForegroundColor Red
            }
        } else {
            Write-Host "ブランチ '$branchName' が見つかりません。" -ForegroundColor Red
            Write-Host "`n利用可能なブランチ:" -ForegroundColor Yellow
            git branch -a | ForEach-Object { 
                if ($_ -match "remotes/origin/(.+)") {
                    Write-Host "  - $($matches[1])" -ForegroundColor Cyan
                }
            }
        }
    }
    
    Write-Host "`n=== セットアップ完了 ===" -ForegroundColor Green
    Write-Host "すべての処理が正常に完了しました。" -ForegroundColor Green
    
    # 管理者権限で実行した場合、ウィンドウを自動で閉じないように一時停止
    Write-Host "`nEnterキーを押して終了してください..." -ForegroundColor Yellow
    Read-Host

} catch {
    Write-Host "`nエラーが発生しました: $_" -ForegroundColor Red
    Write-Host "`nEnterキーを押して終了してください..." -ForegroundColor Yellow
    Read-Host
    exit 1
}