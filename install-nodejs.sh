#!/usr/bin/env bash

set -e

# === 設定（後で変更しやすいよう変数化） =====================
NODE_MAJOR_VERSION=24   # ← Node.js のメジャーバージョンを指定（例: 18 / 20 / 22 / 24）
# ================================================================

echo "Installing Node.js major version: $NODE_MAJOR_VERSION"

# --- 最新 nvm バージョンを取得 ---
echo "Fetching latest nvm release version..."
NVM_LATEST_TAG=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
  | grep tag_name \
  | cut -d '"' -f 4)

echo "Latest nvm version detected: $NVM_LATEST_TAG"

# --- nvm をインストール ---
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST_TAG}/install.sh | bash

# --- シェルの再読み込み ---
echo "Loading nvm into current shell..."
. "$HOME/.nvm/nvm.sh"

# --- 指定バージョンの Node.js をインストール ---
echo "Installing Node.js v${NODE_MAJOR_VERSION}..."
nvm install "$NODE_MAJOR_VERSION"

# --- インストール確認 ---
echo "Node.js installed version:"
node -v

echo "npm installed version:"
npm -v

echo "Installation completed successfully."
