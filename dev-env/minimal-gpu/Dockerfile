FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04

# 対話モード防止
ENV DEBIAN_FRONTEND=noninteractive

# --- 1. システムパッケージ ---
# 最小構成
RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    sudo \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# ロケール設定
RUN locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# ユーザー設定
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER ubuntu
WORKDIR /home/ubuntu

# --- 2. Pixi のインストール ---
RUN curl -fsSL https://pixi.sh/install.sh | bash

# パスを通す
ENV PATH="/home/ubuntu/.pixi/bin:$PATH"

# 起動スクリプトの配置
COPY --chown=ubuntu:ubuntu entrypoint.sh /home/ubuntu/entrypoint.sh
RUN chmod +x /home/ubuntu/entrypoint.sh

ENTRYPOINT ["/home/ubuntu/entrypoint.sh"]