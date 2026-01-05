FROM ubuntu:24.04

# 対話モード防止
ENV DEBIAN_FRONTEND=noninteractive

# --- 1. システムパッケージと Fcitx 5 のインストール ---
# Pixiのインストールに curl が必要になるため追加
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    locales \
    sudo \
    x11-xserver-utils \
    libxcursor-dev \
    alsa-utils \
    libegl1 \
    libgl1 \
    fcitx5 \
    fcitx5-mozc \
    fcitx5-frontend-qt5 \
    kde-config-fcitx5 \
    dbus-x11 \
    im-config \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    fonts-ipafont \
    fonts-takao \
    fonts-ubuntu \
    libxkbcommon-x11-0 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-xinerama0 \
    libxcb-xinput0 \
    libxcb-xfixes0 \
    libx11-xcb1 \
    && rm -rf /var/lib/apt/lists/*

# ロケール設定
RUN locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# フォントキャッシュの更新
RUN fc-cache -fv

# ユーザー設定: ubuntu ユーザーを使用 (UID 1000は通常デフォルトで存在しますが、念のためsudo権限付与)
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER ubuntu
WORKDIR /home/ubuntu

# --- 2. Pixi のインストール ---
# 公式インストーラーを使用
RUN curl -fsSL https://pixi.sh/install.sh | bash

# シェルの再起動の代わりに、ENVでパスを通す (Dockerビルドでの定石)
ENV PATH="/home/ubuntu/.pixi/bin:$PATH"

# 環境変数 (Fcitx 5 設定)
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV DefaultIMModule=fcitx

# 起動スクリプトの配置
COPY --chown=ubuntu:ubuntu entrypoint.sh /home/ubuntu/entrypoint.sh
RUN chmod +x /home/ubuntu/entrypoint.sh

ENTRYPOINT ["/home/ubuntu/entrypoint.sh"]