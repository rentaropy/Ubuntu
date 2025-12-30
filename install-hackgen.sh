#!/usr/bin/env bash
set -e

echo "=== Install latest HackGen font (from GitHub releases) ==="

#######################################
# Dependency check
#######################################
echo "Checking required commands..."

for cmd in curl jq unzip fc-cache; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING_CMDS+=("$cmd")
  fi
done

if [ -n "${MISSING_CMDS[*]}" ]; then
  echo "Installing missing packages: ${MISSING_CMDS[*]}"
  sudo apt-get update
  sudo apt-get install -y \
    curl \
    jq \
    unzip \
    fontconfig
fi

#######################################
# Fetch latest release info
#######################################
REPO="yuru7/HackGen"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Fetching latest release information..."
TAG_NAME=$(curl -s "$API_URL" | jq -r .tag_name)

if [ -z "$TAG_NAME" ] || [ "$TAG_NAME" = "null" ]; then
  echo "Failed to retrieve the latest release tag."
  exit 1
fi

echo "Latest release detected: $TAG_NAME"

#######################################
# Download
#######################################
ZIP_NAME="HackGen_${TAG_NAME}.zip"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${TAG_NAME}/${ZIP_NAME}"

echo "Downloading $ZIP_NAME..."
curl -L -o "$ZIP_NAME" "$DOWNLOAD_URL"

#######################################
# Install fonts
#######################################
WORK_DIR="HackGen_${TAG_NAME}"
DEST_DIR="$HOME/.local/share/fonts"

echo "Extracting archive..."
unzip -o "$ZIP_NAME" -d "$WORK_DIR"

echo "Installing fonts to $DEST_DIR..."
mkdir -p "$DEST_DIR"
find "$WORK_DIR" -type f -name "*.ttf" -exec cp {} "$DEST_DIR"/ \;

echo "Updating font cache..."
fc-cache -fv "$DEST_DIR"

#######################################
# Cleanup
#######################################
echo "Cleaning up temporary files..."
rm -rf "$WORK_DIR" "$ZIP_NAME"

echo
echo "HackGen font installation completed successfully."
echo "Please restart applications to apply the new fonts."
