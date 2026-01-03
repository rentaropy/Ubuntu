#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================"
echo " Spyder Auto-Install & Japanese Input Setup"
echo "========================================"

# --- 1. Identify System Plugin Path ---
echo "--- 1. Searching for Fcitx Qt5 plugin ---"

# Check if the package is installed
if ! dpkg -l | grep -q fcitx-frontend-qt5; then
    echo "Error: 'fcitx-frontend-qt5' is not installed."
    echo "Please run: sudo apt install -y fcitx-frontend-qt5"
    exit 1
fi

# Dynamically get the plugin path using dpkg -L
SOURCE_LIB=$(dpkg -L fcitx-frontend-qt5 | grep "libfcitxplatforminputcontextplugin.so" | head -n 1)

# Verify if the path was found and the file exists
if [ -z "$SOURCE_LIB" ] || [ ! -f "$SOURCE_LIB" ]; then
    echo "Error: Plugin file could not be found in the package."
    echo "Please check your fcitx installation."
    exit 1
fi

echo "Plugin found at: $SOURCE_LIB"


# --- 2. Download ---
echo "--- 2. Downloading Spyder installer ---"
if [ -f "Spyder-Linux-x86_64.sh" ]; then
    rm Spyder-Linux-x86_64.sh
fi
wget -O Spyder-Linux-x86_64.sh https://github.com/spyder-ide/spyder/releases/latest/download/Spyder-Linux-x86_64.sh


# --- 3. Install ---
echo "--- 3. Installing Spyder (Batch mode) ---"
chmod +x Spyder-Linux-x86_64.sh
./Spyder-Linux-x86_64.sh -b


# --- 4. Configure Japanese Input ---
echo "--- 4. Configuring Japanese input plugin ---"

# Search for plugin directory
TARGET_DIR=$(find ~/.local -type d -name "platforminputcontexts" 2>/dev/null | grep "spyder" | head -n 1)

if [ -z "$TARGET_DIR" ]; then
    echo "Not found in standard path. Searching entire home directory..."
    TARGET_DIR=$(find ~/ -type d -name "platforminputcontexts" 2>/dev/null | grep "spyder" | head -n 1)
fi

if [ -n "$TARGET_DIR" ]; then
    echo "Spyder plugin directory: $TARGET_DIR"
    ln -sf "$SOURCE_LIB" "$TARGET_DIR/"
    
    if [ $? -eq 0 ]; then
        echo "Success: Symbolic link created."
    else
        echo "Failure: Failed to create symbolic link."
        exit 1
    fi
else
    echo "Warning: Could not automatically locate Spyder plugin folder."
    echo "Please verify that Spyder was installed correctly."
fi


# --- 5. Cleanup ---
echo "--- 5. Removing temporary files ---"
rm Spyder-Linux-x86_64.sh

echo "========================================"
echo " Setup Completed."
echo ""
echo " IMPORTANT: To update the system PATH, a restart is required."
echo " 1. Close this terminal window completely."
echo " 2. Open a new WSL terminal."
echo " 3. Type 'spyder &' to start."
echo "========================================"
