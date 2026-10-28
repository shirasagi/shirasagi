# LINE 連携（Messaging API / LINE Login）を確認するための実験用コンテナ。
#
# - Ruby は本番プロビジョニング（bin/install.sh）と同じ 3.3.9 に合わせる。
# - LINE 連携は line-bot-api / omniauth-line gem の HTTPS 通信だけで完結し、OS コマンドを呼ばない。
#   そのためベースは公式 ruby イメージ（Debian）とし、OS レベルの追加は次の 2 つに限る。
#     * ImageMagick: リッチメニュー／イメージマップ画像のサムネイル生成（mini_magick）
#     * Node.js + yarn: 管理画面の JS/CSS を webpack でビルドするため（本番 bin/install.sh の 24.x に合わせる）
# - MeCab / Open JTalk / Chrome など LINE 連携に無関係な依存は入れない。
ARG RUBY_VERSION=3.3.9
FROM ruby:${RUBY_VERSION}

ENV LANG=C.UTF-8 \
    TZ=Asia/Tokyo \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg imagemagick && \
    rm -rf /var/lib/apt/lists/*

ARG NODE_MAJOR=24
RUN curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g yarn@1.22.22 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
EXPOSE 3000
