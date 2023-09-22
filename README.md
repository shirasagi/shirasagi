# SHIRASAGI

SHIRASAGI is Contents Management System.

## Code Status

[![Ruby](https://github.com/shirasagi/shirasagi/actions/workflows/ruby.yml/badge.svg)](https://github.com/shirasagi/shirasagi/actions/workflows/ruby.yml)
[![Coverage Status](https://coveralls.io/repos/shirasagi/shirasagi/badge.png)](https://coveralls.io/r/shirasagi/shirasagi)
[![Code Climate](https://api.codeclimate.com/v1/badges/e6274965ec75ce8fd605/test_coverage)](https://codeclimate.com/github/shirasagi/shirasagi/test_coverage)
[![GitHub version](https://badge.fury.io/gh/shirasagi%2Fshirasagi.svg)](http://badge.fury.io/gh/shirasagi%2Fshirasagi)

## Documentation

- [公式サイト](http://ss-proj.org/)
  - [オンラインデモ](https://www.ss-proj.org/download/demo.html)
  - [ダウンロード](https://www.ss-proj.org/download/)
  - [よくある質問記事](https://www.ss-proj.org/faq/docs/)
- [開発マニュアル](http://shirasagi.github.io/)

## Platform

- AlmaLinux, RockyLinux, Ubuntu
- Ruby 3.0 or 3.1
- Ruby on Rails 6.1
- MongoDB 4.4 or 6.0
- Unicorn

## Installation (Auto)

- AlmaLinux8 の環境で実行してください。<br />
- 一般ユーザーで実行する場合はユーザーで実行する場合は、sudo が利用できることを確認してください。<br />
- パラメーターの"example.jp"には、ブラウザでアクセスする際のドメイン名または、IPアドレスを指定してください。<br />

```
$ su - user-which-executes-shirasagi-server
$ curl https://raw.githubusercontent.com/shirasagi/shirasagi/master/bin/install.sh | bash -s example.jp
```

## Installation (AlmaLinux)

拡張機能（ふりがな、読み上げ、オープンデータ等）や詳細なインストール手順は[開発マニュアル](http://shirasagi.github.io/)をご確認ください。

### パッケージのダウンロード

```
$ su -
# dnf -y install epel-release wget
# dnf config-manager --disable epel
# dnf --enablerepo=epel -y update epel-release
# dnf -y groupinstall "Development tools"
# dnf -y --enablerepo=epel,powertools install ImageMagick ImageMagick-devel openssl3
```

### MongoDB のインストール

```
$ su -
# vi /etc/yum.repos.d/mongodb-org-6.0.repo
```

```
[mongodb-org-6.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/6.0/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc
```

```
# dnf install -y --enablerepo=mongodb-org-6.0 mongodb-org
# systemctl start mongod
# systemctl enable mongod
```

### asdf のインストール

```
$ su -
# git clone https://github.com/asdf-vm/asdf.git ~/.asdf
# vi ~/.bashrc
---(追記)
. $HOME/.asdf/asdf.sh
. $HOME/.asdf/completions/asdf.bash
---
# source ~/.bashrc
```

### Ruby のインストール

```
$ su -
# asdf plugin add ruby
# asdf install ruby 3.1.4
# asdf global ruby 3.1.4
```

### Nodejs のインストール

```
$ su -
# asdf plugin add nodejs
# asdf install nodejs 20.5.0
# asdf global nodejs 20.5.0
# npm install -g yarn
```

### SHIRASAGI のインストール

SHIRASAGI のダウンロード (stable)

```
$ su -
# git clone -b stable https://github.com/shirasagi/shirasagi /var/www/shirasagi
```

設定ファイルの設置と gem のインストール

```
$ su -
# cd /var/www/shirasagi
# cp -n config/samples/*.{yml,rb} config/
# bundle install --without development test
# ./bin/deploy
```

Web サーバの起動

```
$ su -
# bundle exec rake unicorn:start
```

## サイトの作成

データベース（インデックス）の作成

```
$ su -
# bundle exec rake db:drop
# bundle exec rake db:create_indexes
```

新規サイトの追加

```
$ su -
# bundle exec rake ss:create_site data='{ name: "サイト名", host: "www", domains: "localhost:3000" }'
```

サンプルデータ (自治体サンプル) の投入

```
$ su -
# bundle exec rake db:seed name=demo site=www
```

## サイトの確認

#### 管理画面

http://localhost:3000/.mypage にアクセスするとログイン画面が表示されます。<br />
サイト名のリンクをクリックすると、登録したデモデータを確認・編集することができます。<br />
[ ユーザーID： admin , パスワード： pass ]

#### 公開画面

http://localhost:3000/ にアクセスすると登録したデモサイトが表示されます。

## 開発・テスト環境

`.env`というファイルをプロジェクトルートに用意すれば各種設定をお好みのものに切り替えられます。

(設定例)

- デフォルトで`warn`になっているログレベルを`debug`にしたい場合。
- テスト時にデフォルトで実行されるカバレッジ計測を省きたい場合。

```
DEVELOPMENT_LOG_LEVEL=debug
ANALYZE_COVERAGE=disabled
```

## その他機能の利用方法

- [グループウェアの始め方](http://shirasagi.github.io/start/gws.html)
- [ウェブメールの始め方](http://shirasagi.github.io/start/webmail.html)
