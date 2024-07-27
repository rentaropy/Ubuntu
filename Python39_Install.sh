#!/bin/bash
#wget https://raw.githubusercontent.com/maemune/Unix/main/Python_Install.sh && nano ./Python_Install.sh && chmod u+x ./Python_Install.sh && ./Python_Install.sh

# エラーハンドリングを有効化
set -e

# 必要なパッケージのインストール
sudo apt update && sudo apt install -y software-properties-common

# deadsnakes PPAの追加
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt update

# Python 3.9のインストール
sudo apt install -y python3.9 python3.9-dev python3.9-distutils

# 必要な開発ツールのインストール
sudo apt-get install -y libreadline-dev zlib1g-dev libncursesw5-dev libssl-dev libsqlite3-dev libgdbm-dev libc6-dev libbz2-dev
sudo apt-get install -y build-essential libffi-dev libexpat1-dev liblzma-dev python3-testresources

# pipのインストール
curl -sS https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3.9 get-pip.py
sudo python3.9 -m pip install --upgrade pip
rm get-pip.py

# 必要に応じてpipコマンドを移動
sudo mv /usr/local/bin/pip /usr/local/bin/pip_ && sudo mv /usr/local/bin/pip3.9 /usr/local/bin/pip

# 環境変数の更新
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.profile

# 確認のためにシェルを再起動
exec $SHELL

exit
