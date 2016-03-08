SHIRASAGI
=========

SHIRASAGI is Contents Management System.

Code Status
-----------

[![Build Status](https://travis-ci.org/shirasagi/shirasagi.svg?branch=master)](https://travis-ci.org/shirasagi/shirasagi)
[![Code Climate](https://codeclimate.com/github/shirasagi/shirasagi/badges/gpa.svg)](https://codeclimate.com/github/shirasagi/shirasagi)
[![Coverage Status](https://coveralls.io/repos/shirasagi/shirasagi/badge.png)](https://coveralls.io/r/shirasagi/shirasagi)
[![GitHub version](https://badge.fury.io/gh/shirasagi%2Fshirasagi.svg)](http://badge.fury.io/gh/shirasagi%2Fshirasagi)
[![Inline docs](http://inch-ci.org/github/shirasagi/shirasagi.png?branch=master)](http://inch-ci.org/github/shirasagi/shirasagi)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/shirasagi/shirasagi?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Stories in Ready](https://badge.waffle.io/shirasagi/shirasagi.svg?label=ready&title=Ready)](http://waffle.io/shirasagi/shirasagi)

Documentation
-------------

- [公式サイト](http://ss-proj.org/)
- [開発マニュアル](http://shirasagi.github.io/)

Platform
--------

- CentOS, Ubuntu
- Ruby 2.3
- Ruby on Rails 4
- MongoDB 3
- Unicorn

Installation (CentOS 7)
=======================

拡張機能（ふりがな、読み上げ、オープンデータ等）や詳細なインストール手順は[開発マニュアル](http://shirasagi.github.io/)をご確認ください。

## パッケージのダウンロード

```
$ su -
# yum -y install wget git ImageMagick ImageMagick-devel
```

## MongoDB のインストール

```
# vi /etc/yum.repos.d/mongodb-org-3.2.repo
```

```
[mongodb-org-3.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64/
gpgcheck=0
enabled=0
```

```
# yum install -y --enablerepo=mongodb-org-3.2 mongodb-org
# systemctl start mongod
# systemctl enable mongod
```

## Ruby(RVM) のインストール

```
# gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
# \curl -sSL https://get.rvm.io | sudo bash -s stable
# source /etc/profile
# rvm install 2.3.0
# rvm use 2.3.0 --default
# gem install bundler
```

## SHIRASAGI のインストール

SHIRASAGI のダウンロード (stable)

```
$ git clone -b stable --depth 1 https://github.com/shirasagi/shirasagi /var/www/shirasagi
```

設定ファイルの設置と gem のインストール

```
$ cd /var/www/shirasagi
$ cp -n config/samples/*.{yml,rb} config/
$ bundle install --without development test
```

Web サーバの起動

```
$ rake unicorn:start
```

## サイトの作成

データベース（インデックス）の作成

```
$ rake db:drop
$ rake db:create_indexes
```

新規サイトの追加

```
$ rake ss:create_site data='{ name: "サイト名", host: "www", domains: "localhost:3000" }'
```

サンプルデータ (自治体サンプル) の投入

```
$ rake db:seed name=demo site=www
```

## サイトの確認

### 管理画面
http://localhost:3000/.mypage にアクセスするとログイン画面が表示されます。<br />
サイト名のリンクをクリックすると、登録したデモデータを確認・編集することができます。<br />
[ ユーザーID： admin , パスワード： pass ]

### 公開画面
http://localhost:3000/ にアクセスすると登録したデモサイトが表示されます。

## 開発・テスト環境

`.env`というファイルをプロジェクトルートに用意すれば各種設定をデフォルトのものからお好みのものに切り替えられます。

### 例

デフォルトで`warn`になっているログレベルを`debug`にしたい場合。

テスト時にデフォルトで実行されるカバレッジ計測を省きたい場合。

```
DEVELOPMENT_LOG_LEVEL=debug
ANALYZE_COVERAGE=disabled
```
