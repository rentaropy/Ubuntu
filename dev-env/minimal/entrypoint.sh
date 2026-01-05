#!/bin/bash
set -e

# ワークスペースディレクトリ
WORKSPACE_DIR="/home/ubuntu/workspace"

# ディレクトリがない場合はエラー (マウント忘れ防止)
if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "ERROR: Workspace directory not mounted!"
    exit 1
fi

cd "$WORKSPACE_DIR"

# --- Pixi 環境のセットアップ ---
# pixi.toml がない場合 = 初回セットアップ
if [ ! -f "pixi.toml" ]; then
    echo "--- Initializing Pixi Project (Minimal) ---"
    pixi init .
else
    # 2回目以降: 環境の同期
    echo "--- Syncing Pixi Environment ---"
    pixi install
fi

echo "Setup complete."

# Docker Compose の command (sleep infinity) を実行
exec "$@"