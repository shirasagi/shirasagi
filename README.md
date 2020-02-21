SHIRASAGI
=========

SHIRASAGI is Contents Management System.

Code Status
-----------

[![Build Status](https://travis-ci.org/shirasagi/shirasagi.svg?branch=master)](https://travis-ci.org/shirasagi/shirasagi)
[![Coverage Status](https://coveralls.io/repos/shirasagi/shirasagi/badge.png)](https://coveralls.io/r/shirasagi/shirasagi)
[![Code Climate](https://api.codeclimate.com/v1/badges/e6274965ec75ce8fd605/test_coverage)](https://codeclimate.com/github/shirasagi/shirasagi/test_coverage)
[![GitHub version](https://badge.fury.io/gh/shirasagi%2Fshirasagi.svg)](http://badge.fury.io/gh/shirasagi%2Fshirasagi)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/shirasagi/shirasagi?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
<!-- [![Inline docs](http://inch-ci.org/github/shirasagi/shirasagi.png?branch=master)](http://inch-ci.org/github/shirasagi/shirasagi) -->

Documentation
-------------

- [公式サイト](http://ss-proj.org/)
    - [オンラインデモ](https://www.ss-proj.org/download/demo.html)
    - [ダウンロード](https://www.ss-proj.org/download/)
    - [よくある質問記事](https://www.ss-proj.org/faq/docs/)
- [開発マニュアル](http://shirasagi.github.io/)

Platform
--------

- CentOS, Ubuntu
- Ruby 2.6
- Ruby on Rails 5.2
- MongoDB 3
- Unicorn

Installation (Auto)
-------------------

- CentOS7の環境で実行してください。<br />
- 一般ユーザーで実行する場合は、sudoが利用できることを確認してください。<br />
- パラメーターの"example.jp"には、ブラウザでアクセスする際のドメイン名または、IPアドレスを指定してください。<br />

```
$ su - user-which-executes-shirasagi-server
$ curl https://raw.githubusercontent.com/shirasagi/shirasagi/master/bin/install.sh | bash -s example.jp
```

Installation (CentOS 7)
-----------------------

拡張機能（ふりがな、読み上げ、オープンデータ等）や詳細なインストール手順は[開発マニュアル](http://shirasagi.github.io/)をご確認ください。

### パッケージのダウンロード

```
$ su -
# yum -y install wget git ImageMagick ImageMagick-devel
```

### MongoDB のインストール

```
# vi /etc/yum.repos.d/mongodb-org-3.4.repo
```

```
[mongodb-org-3.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.4/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
```

```
# yum install -y --enablerepo=mongodb-org-3.4 mongodb-org
# systemctl start mongod
# systemctl enable mongod
```

### Ruby(RVM) のインストール

```
# gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
# \curl -sSL https://get.rvm.io | sudo bash -s stable
# source /etc/profile
# rvm install 2.6.3
# rvm use 2.6.3 --default
# gem install bundler
```

### SHIRASAGI のインストール

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
