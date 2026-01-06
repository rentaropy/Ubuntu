ARG ENVIRONMENT=spyder-gpu

# Determine conditions from ENVIRONMENT
FROM nvidia/cuda:12.9.1-cudnn-devel-ubuntu24.04 AS base-gpu
FROM ubuntu:24.04 AS base-cpu

# minimal-gpu or spyder-gpu uses a GPU image
FROM base-gpu AS final-minimal-gpu
FROM base-gpu AS final-spyder-gpu
FROM base-cpu AS final-minimal
FROM base-cpu AS final-spyder

FROM final-${ENVIRONMENT} AS selected

ENV DEBIAN_FRONTEND=noninteractive

# Installing Common Packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    locales \
    sudo \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Installing the Spyder Package (Only for spyder or spyder-gpu)
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

# Locale Settings
RUN locale-gen ja_JP.UTF-8
ENV LANG=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:ja
ENV LC_ALL=ja_JP.UTF-8

# Spyder Font Cache Update
RUN case "$ENVIRONMENT" in \
    (spyder|spyder-gpu) fc-cache -fv ;; \
    esac

# sudoers configuration
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 

USER ubuntu
WORKDIR /home/ubuntu

# Pixi Installation
RUN curl -fsSL https://pixi.sh/install.sh | bash

ENV PATH="/home/ubuntu/.pixi/bin:$PATH"

# Spyder IME Settings
ENV GTK_IM_MODULE=fcitx
ENV QT_IM_MODULE=fcitx
ENV XMODIFIERS=@im=fcitx
ENV DefaultIMModule=fcitx

# Copy entrypoint.sh
COPY --chown=ubuntu:ubuntu entrypoint.sh /home/ubuntu/entrypoint.sh
RUN chmod +x /home/ubuntu/entrypoint.sh

ENTRYPOINT ["/home/ubuntu/entrypoint.sh"]