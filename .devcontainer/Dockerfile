FROM mcr.microsoft.com/devcontainers/ruby:3.2

RUN apt update && \
  apt install --no-install-recommends -y \
    build-essential \
    fonts-noto-cjk \
    git \
    imagemagick \
    jp \
    lame \
    libmecab-dev \
    libvips \
    libyaml-dev \
    ldap-utils \
    mecab \
    mecab-ipadic-utf8 \
    nkf \
    open-jtalk \
    open-jtalk-mecab-naist-jdic \
    pkg-config \
    sox

RUN wget -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y /tmp/google-chrome-stable_current_amd64.deb && \
    rm /tmp/google-chrome-stable_current_amd64.deb

#RUN locale-gen ja_JP
#RUN update-locale LANG=ja_JP.UTF-8

# RUN su vscode -c "gem install rails:7.1.3"
RUN su vscode -c "/usr/local/rvm/bin/rvm fix-permissions"
