#!/usr/bin/env bash
set -e

echo "=== Enable Japanese Input Method in WSL (fcitx5 + Mozc) ==="
echo "This script will configure environment variables and input method."
echo "Logout / re-login is required to complete the setup."
echo

#######################################
# DISPLAY setting
#######################################
if ! grep -q 'export DISPLAY=:0.0' ~/.profile 2>/dev/null; then
  echo "Configuring DISPLAY environment variable..."
  echo 'export DISPLAY=:0.0' >> ~/.profile
fi

#######################################
# Locale configuration (Japanese)
#######################################
echo "Installing Japanese language pack..."
sudo apt-get update
sudo apt-get install -y language-pack-ja

echo "Updating system locale to ja_JP.UTF-8..."
sudo update-locale LANG=ja_JP.UTF-8

#######################################
# Keyboard layout (JP)
#######################################
echo "Installing X keyboard utilities..."
sudo apt-get install -y x11-xkb-utils

echo "Setting keyboard layout to Japanese..."
setxkbmap -layout jp || true

if ! grep -q 'setxkbmap -layout jp' ~/.bashrc 2>/dev/null; then
  echo "Persisting keyboard layout configuration..."
  echo 'setxkbmap -layout jp 2>/dev/null' >> ~/.bashrc
fi

#######################################
# fcitx5 + Mozc
#######################################
echo "Installing fcitx5 and Mozc..."
sudo apt-get install -y fcitx5-mozc

echo "Setting fcitx5 as default input method..."
im-config -n fcitx5

#######################################
# Environment variables for IME
#######################################
if ! grep -q 'GTK_IM_MODULE=fcitx5' ~/.bashrc 2>/dev/null; then
  echo "Configuring input method environment variables..."
  cat <<'EOF' >> ~/.bashrc

# ---- fcitx5 environment variables ----
export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
export DefaultIMModule=fcitx5
export INPUT_METHOD=fcitx5

# Start fcitx5 only on login shell
if [ "$SHLVL" -eq 1 ]; then
  (fcitx5 --disable=wayland -d --verbose '*'=0 &)
fi
# -------------------------------------
EOF
fi

#######################################
# Finish
#######################################
echo
echo "============================================================"
echo "Initial configuration is complete."
echo
echo "Please LOGOUT and LOGIN again (exit WSL completely)."
echo
echo "After re-login, execute the following commands IN THIS ORDER:"
echo
echo "  1. sudo apt-get install -y fonts-noto-cjk"
echo "     (Required to avoid garbled text in fcitx5-configtool)"
echo
echo "  2. fcitx5-configtool"
echo "     (Refer to: https://zenn.dev/masinc/articles/464bea11f2d47e#fcitx5-%E3%81%AE%E8%A8%AD%E5%AE%9A)"
echo "      Note: To start with Half-width Alphanumeric input, keep Mozc as the second item from the top."
echo "============================================================"
echo
echo "You can logout now by running:"
echo "  exit"
