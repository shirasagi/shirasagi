# SHIRASAGI

SHIRASAGI is Contents Management System.

## Code Status

[![Ruby](https://github.com/shirasagi/shirasagi/actions/workflows/ruby.yml/badge.svg)](https://github.com/shirasagi/shirasagi/actions/workflows/ruby.yml)
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
- Ruby 3.3 or 3.4
- Ruby on Rails 8.1
- MongoDB 7.0 or 8.0
- Puma / Unicorn
- Node.js 24
- Elasticsearch 8

## Installation (Auto)

- AlmaLinux8 の環境で実行してください。<br />
- 一般ユーザーで実行する場合は、sudo が利用できることを確認してください。<br />
- パラメーターの"example.jp"には、ブラウザでアクセスする際のドメイン名または、IPアドレスを指定してください。<br />

例) 一般ユーザが ssuser の場合

```
$ su - ssuser
$ curl https://raw.githubusercontent.com/shirasagi/shirasagi/master/bin/install.sh | bash -s example.jp
```

## Installation (AlmaLinux)

- 本手順は簡易的に動作確認を行う為の最小構成の手順となります。
正式にサービスとしてご利用の際は、フロントにNginx等のWEBサーバを立て、
セキュリティに配慮した設定を実施頂くことを推奨いたします。<br />
Nginxの導入につきましては開発マニュアルの[Nginxのインストール](https://shirasagi.github.io/installation/nginx.html)
をご確認ください。<br />

- 拡張機能（ふりがな、読み上げ、オープンデータ等）や詳細なインストール手順は[開発マニュアル](http://shirasagi.github.io/)をご確認ください。

### パッケージのダウンロード

```
$ sudo dnf -y install epel-release wget
$ sudo dnf config-manager --disable epel
$ sudo dnf --enablerepo=epel -y update epel-release
$ sudo dnf -y groupinstall "Development tools"
$ sudo dnf -y --enablerepo=epel,powertools install ImageMagick ImageMagick-devel openssl-devel libyaml-devel mecab mecab-devel mecab-ipadic
```

### MongoDB のインストール

```
$ sudo vi /etc/yum.repos.d/mongodb-org-8.0.repo
```

```
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-8.0.asc
```

```
$ sudo dnf install -y --enablerepo=mongodb-org-8.0 mongodb-org
$ sudo systemctl enable --now mongod
```

### asdf のインストール

```
$ wget https://github.com/asdf-vm/asdf/releases/download/v0.18.1/asdf-v0.18.1-linux-amd64.tar.gz
$ tar -xzf asdf-v0.18.1-linux-amd64.tar.gz
$ sudo mv asdf /usr/local/bin/
$ vi ~/.bashrc
```

```
---(追記)
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
---
```

```
$ source ~/.bashrc
```

### Ruby のインストール

```
$ asdf plugin add ruby
$ asdf install ruby 3.4.12
$ asdf set ruby 3.4.12
```

### Nodejs のインストール

```
$ asdf plugin add nodejs
$ asdf install nodejs 24.17.0
$ asdf set nodejs 24.17.0
$ npm install -g yarn
```

### SHIRASAGI のインストール

SHIRASAGI のダウンロード (stable)

```
$ sudo mkdir -p /var/www
$ git clone -b stable https://github.com/shirasagi/shirasagi ~/shirasagi
$ sudo mv ~/shirasagi /var/www/
```

Mecab-ruby のインストール

```
$ cp -arp /var/www/shirasagi/vendor/mecab/mecab-ruby-0.996.tar.gz ./
$ tar xvzf mecab-ruby-0.996.tar.gz && cd mecab-ruby-0.996
$ ruby extconf.rb && make && make install
```

設定ファイルの設置と gem のインストール

```
$ cd /var/www/shirasagi
$ cp -n config/samples/*.{yml,rb} config/
$ bundle install --without development test
$ bundle exec rails credentials:edit
$ bundle exec bin/deploy
```

> `GLIBC_2.29` 関する警告が発生された場合には、`bundle config set force_ruby_platform true` を実行し再度 `bundle install` から実行してください。

Web サーバの起動

```
$ sudo cp -n /var/www/shirasagi/bin/puma.service /etc/systemd/system/puma.service
$ sudo sed -i 's/User=root/User=ssuser/g' /etc/systemd/system/puma.service
$ sudo systemctl daemon-reload
$ sudo systemctl enable --now puma
```

## サイトの作成

データベース（インデックス）の作成

```
$ bundle exec rake db:drop
$ bundle exec rake db:create_indexes
```

新規サイトの追加

```
$ bundle exec rake ss:create_site data='{ name: "サイト名", host: "www", domains: "localhost:3000" }'
```

サンプルデータ (自治体サンプル) の投入

```
$ bundle exec rake db:seed name=demo site=www
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
