ARG ENVIRONMENT=spyder-gpu

# ENVIRONMENTから条件を判定
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04 AS base-gpu
FROM ubuntu:24.04 AS base-cpu

# minimal-gpu または spyder-gpu の場合はGPUイメージを使用
FROM base-gpu AS final-minimal-gpu
FROM base-gpu AS final-spyder-gpu
FROM base-cpu AS final-minimal
FROM base-cpu AS final-spyder

FROM final-${ENVIRONMENT} AS selected

ENV DEBIAN_FRONTEND=noninteractive

# 共通パッケージのインストール
RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    sudo \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Spyder用パッケージのインストール（spyder または spyder-gpuの場合のみ）
ARG ENVIRONMENT
RUN case "$ENVIRONMENT" in \
    spyder|spyder-gpu) \
        apt-get update && apt-get install -y \
            wget \
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
        && rm -rf /var/lib/apt/lists/* ;; \
    esac

# ロケール設定
RUN locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# Spyder用フォントキャッシュ更新
RUN case "$ENVIRONMENT" in \
    (spyder|spyder-gpu) fc-cache -fv ;; \
    esac

# sudoers設定
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER ubuntu
WORKDIR /home/ubuntu

# Pixiインストール
RUN curl -fsSL https://pixi.sh/install.sh | bash

ENV PATH="/home/ubuntu/.pixi/bin:$PATH"

# Spyder用IME設定
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV DefaultIMModule=fcitx

# entrypoint.shのコピー
COPY --chown=ubuntu:ubuntu entrypoint.sh /home/ubuntu/entrypoint.sh
RUN chmod +x /home/ubuntu/entrypoint.sh

ENTRYPOINT ["/home/ubuntu/entrypoint.sh"]