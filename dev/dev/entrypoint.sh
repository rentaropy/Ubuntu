#!/bin/bash

set -e

# Spyder環境の場合のみ、GUI関連の設定を実行
if [[ "$ENVIRONMENT" == "spyder" || "$ENVIRONMENT" == "spyder-gpu" ]]; then
    export XDG_RUNTIME_DIR=/tmp/runtime-ubuntu
    if [ ! -d "$XDG_RUNTIME_DIR" ]; then
        mkdir -p "$XDG_RUNTIME_DIR"
        chmod 700 "$XDG_RUNTIME_DIR"
    fi
    
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
        eval $(dbus-launch --sh-syntax)
    fi
    
    xset r off > /dev/null 2>&1 || true
    
    echo "Starting Fcitx 5..."
    fcitx5 -d &> /dev/null
    sleep 2
fi

WORKSPACE_DIR="/home/ubuntu/workspace"

if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "ERROR: Workspace directory not mounted!"
    exit 1
fi

cd "$WORKSPACE_DIR"

if [ ! -f "pixi.toml" ]; then
    echo "--- Initializing Pixi Project ---"
    pixi init .
    
    # Spyder環境の場合のみSpyderをインストール
    if [[ "$ENVIRONMENT" == "spyder" || "$ENVIRONMENT" == "spyder-gpu" ]]; then
        echo "--- Installing Spyder via Pixi ---"
        pixi add spyder
    fi
else
    echo "--- Syncing Pixi Environment ---"
    pixi install
fi

# Minimal環境の場合はここで終了（sleep infinityを実行）
if [[ "$ENVIRONMENT" == "minimal" || "$ENVIRONMENT" == "minimal-gpu" ]]; then
    echo "Setup complete. Container is ready for VSCode connection."
    exec sleep infinity
fi

# Spyder環境の場合はSpyderを起動
echo "Linking Fcitx 5 Qt plugin to Pixi environment..."
SOURCE_LIB=$(dpkg -L fcitx5-frontend-qt5 | grep "libfcitx5platforminputcontextplugin.so" | head -n 1)
TARGET_DIR=$(find .pixi -type d -path "*/plugins/platforminputcontexts" 2>/dev/null | head -n 1)

if [ -n "$SOURCE_LIB" ] && [ -n "$TARGET_DIR" ]; then
    ln -sf "$SOURCE_LIB" "$TARGET_DIR/"
fi

echo "Launching Spyder via Pixi..."
pixi run spyder