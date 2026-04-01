FROM mcr.microsoft.com/devcontainers/ruby:3.3

RUN apt-get update && \
  apt-get install --no-install-recommends -y \
    build-essential \
    fonts-noto-cjk \
    git \
    graphicsmagick \
    imagemagick \
    jp \
    lame \
    libmecab-dev \
    libmp3lame-dev \
    libsox-dev \
    libvips \
    libyaml-dev \
    ldap-utils \
    locales \
    mecab \
    mecab-ipadic-utf8 \
    nkf \
    open-jtalk \
    open-jtalk-mecab-naist-jdic \
    pkg-config \
    sox && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Japanese locale
RUN sed -i '/ja_JP.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=ja_JP.UTF-8 LC_ALL=ja_JP.UTF-8

# Node.js 20 + Yarn
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Chromium (for Capybara E2E tests — works on both amd64 and arm64)
RUN apt-get update && \
    apt-get install -y --no-install-recommends chromium && \
    ln -sf /usr/bin/chromium /usr/bin/google-chrome && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN su vscode -c "/usr/local/rvm/bin/rvm fix-permissions"
