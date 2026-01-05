#!/bin/bash
set -e

WORKSPACE_DIR="/home/ubuntu/workspace"

if [ ! -d "$WORKSPACE_DIR" ]; then
    echo "ERROR: Workspace directory not mounted!"
    exit 1
fi

cd "$WORKSPACE_DIR"

# --- Pixi 環境のセットアップ ---
if [ ! -f "pixi.toml" ]; then
    echo "--- Initializing Pixi Project (Minimal GPU) ---"
    pixi init .
else
    echo "--- Syncing Pixi Environment ---"
    pixi install
fi

echo "Setup complete."

exec "$@"