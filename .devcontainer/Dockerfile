FROM mcr.microsoft.com/devcontainers/ruby:3.2

RUN apt update && \
  apt-get install --no-install-recommends -y \
  build-essential \
  libvips \
  pkg-config \
  git \
  libyaml \
  libyaml-dev \
  ldap-utils \
  jp \
  nkf \

# RUN su vscode -c "gem install rails:7.1.3"
RUN su vscode -c "/usr/local/rvm/bin/rvm fix-permissions"

WORKDIR "/workspaces/shirasagi"
RUN bundle config set --local path vendor/bundle
