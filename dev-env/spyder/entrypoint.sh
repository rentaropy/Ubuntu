#!/bin/bash
set -e

# --- 1. DBus / XDG Runtime 設定 ---
export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
fi

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
   eval $(dbus-launch --sh-syntax)
fi

# キーリピートOFF (多重入力対策)
xset r off > /dev/null 2>&1 || true

# --- 2. Fcitx 5 の起動 ---
echo "Starting Fcitx 5..."
fcitx5 -d &> /dev/null
sleep 2

# ※設定ツール (fcitx5-configtool) は起動しません。
# 必要であれば手動で `docker exec` から実行してください。

# --- 3. Pixi 環境のセットアップ (ホスト同期フォルダ内) ---
WORKSPACE_DIR="/home/ubuntu/workspace"

if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "ERROR: Workspace directory not mounted!"
    exit 1
fi

cd "$WORKSPACE_DIR"

# pixi.toml がない場合 = 初回セットアップ
if [ ! -f "pixi.toml" ]; then
    echo "--- Initializing Pixi Project ---"
    pixi init .
    
    echo "--- Installing Spyder via Pixi ---"
    pixi add spyder
else
    # 2回目以降: pixi.toml の変更を検知して環境を同期・更新
    echo "--- Syncing Pixi Environment (Checking pixi.toml changes) ---"
    pixi install
fi

# --- 4. 日本語入力プラグインのリンク (動的解決) ---
echo "Linking Fcitx 5 Qt plugin to Pixi environment..."

SOURCE_LIB=$(dpkg -L fcitx5-frontend-qt5 | grep "libfcitx5platforminputcontextplugin.so" | head -n 1)
TARGET_DIR=$(find .pixi -type d -path "*/plugins/platforminputcontexts" 2>/dev/null | head -n 1)

if [ -n "$SOURCE_LIB" ] && [ -n "$TARGET_DIR" ]; then
    ln -sf "$SOURCE_LIB" "$TARGET_DIR/"
fi

# --- 5. Spyder の起動 ---
echo "Launching Spyder via Pixi..."
pixi run spyder