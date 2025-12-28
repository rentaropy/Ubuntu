
#!/bin/bash

set -e

echo "=== NVIDIA Container Toolkit Installation Script ==="
echo ""

# 必要なパッケージのインストール
echo "Step 1: Installing required packages..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends curl gnupg2 jq

# GPGキーの追加とリポジトリの設定
echo ""
echo "Step 2: Adding NVIDIA Container Toolkit repository..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# experimentalリポジトリの有効化
echo ""
echo "Step 3: Enabling experimental repository..."
sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list

# パッケージリストの更新
echo ""
echo "Step 4: Updating package list..."
sudo apt-get update

# GitHub APIから最新バージョンを取得
echo ""
echo "Step 5: Fetching latest version from GitHub..."
LATEST_TAG=$(curl -s https://api.github.com/repos/NVIDIA/nvidia-container-toolkit/releases/latest | \
  jq -r '.tag_name')

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
  echo "Error: Failed to fetch latest version from GitHub"
  exit 1
fi

# "v" プレフィックスを削除し、"-1" サフィックスを追加
NVIDIA_CONTAINER_TOOLKIT_VERSION="${LATEST_TAG#v}-1"

echo "Latest version: ${NVIDIA_CONTAINER_TOOLKIT_VERSION}"

# NVIDIA Container Toolkitのインストール
echo ""
echo "Step 6: Installing NVIDIA Container Toolkit..."
sudo apt-get install -y \
  nvidia-container-toolkit=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  nvidia-container-toolkit-base=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container-tools=${NVIDIA_CONTAINER_TOOLKIT_VERSION} \
  libnvidia-container1=${NVIDIA_CONTAINER_TOOLKIT_VERSION}

# Dockerランタイムの設定
echo ""
echo "Step 7: Configuring Docker runtime..."
sudo nvidia-ctk runtime configure --runtime=docker

# Dockerの再起動
echo ""
echo "Step 8: Restarting Docker..."
sudo systemctl restart docker

echo ""
echo "=== Installation completed successfully! ==="
echo "Installed version: ${NVIDIA_CONTAINER_TOOLKIT_VERSION}"
echo ""
echo "You can verify the installation by running:"
echo "  docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi && docker rmi nvidia/cuda:12.0.0-base-ubuntu22.04"
echo
