#!/bin/bash

# Stop script on error
set -e

echo ">>> Starting WSL GUI and Japanese Input Setup..."

# 1. Export DISPLAY to .profile
echo ">>> Configuring DISPLAY variable..."
if grep -q "export DISPLAY=:0.0" ~/.profile; then
    echo "DISPLAY is already set in ~/.profile."
else
    echo 'export DISPLAY=:0.0' >> ~/.profile
    echo "Added DISPLAY=:0.0 to ~/.profile."
fi

# Note: Sourcing .profile here only affects this script's session.
# The user must restart the shell/WSL later for it to take effect globally.
source ~/.profile

# 2. Update and Install Packages
echo ">>> Updating apt repositories..."
sudo apt-get update

echo ">>> Installing required packages (this may take a while)..."
sudo apt-get install -y libxcursor-dev alsa libegl1 fcitx-bin fcitx-mozc dbus-x11 fonts-noto-cjk fonts-ipafont fonts-takao

# 3. Configure Fonts
echo ">>> Configuring font settings (/etc/fonts/local.conf)..."
cat << 'EOS' | sudo tee /etc/fonts/local.conf > /dev/null
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <dir>/mnt/c/Windows/Fonts</dir>
</fontconfig>
EOS
echo "Font configuration created."

# 4. Configure Fcitx Environment Variables
echo ">>> Configuring Fcitx environment variables..."
if grep -q "export GTK_IM_MODULE=fcitx" ~/.profile; then
    echo "Fcitx variables already exist in ~/.profile."
else
    cat << EOS >> ~/.profile

export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export DefaultIMModule=fcitx
fcitx-autostart &> /dev/null
EOS
    echo "Fcitx variables added to ~/.profile."
fi

echo ""
echo "========================================================"
echo "   SETUP COMPLETED SUCCESSFULLY"
echo "========================================================"
echo "Please follow the steps below to finish the configuration:"
echo ""
echo "1. RESTART WSL COMPLETELY."
echo "   Run the following commands in PowerShell or CMD:"
echo "     exit"
echo "     wsl --shutdown"
echo "     wsl -d Ubuntu"
echo ""
echo "2. After restarting, configure Fcitx:"
echo "   Run: $ fcitx-configtool"
echo ""
echo "3. In the Configuration window:"
echo "   - Click the '+' button at the bottom left."
echo "   - Uncheck 'Only Show Current Language'."
echo "   - Search for 'Mozc' and click 'OK' to add it."
echo "   - Close fcitx-configtool."
echo ""
echo "========================================================"
