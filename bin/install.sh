#!/usr/bin/env bash

SS_HOSTNAME=${1:-"example.jp"}
SS_USER=${2:-"$USER"}
SS_DIR=/var/www/shirasagi

PORT_COMPA=8001
PORT_CHILD=8002
PORT_OPEND=8003
PORT_LPSPL=8004

# selinux
sudo sed -i "s/\(^SELINUX=\).*/\1disabled/" /etc/selinux/config
sudo setenforce 0

sudo dnf -y upgrade almalinux-release
sudo dnf -y groupinstall "Development tools" --setopt=group_package_types=mandatory,default,optional
sudo dnf -y install epel-release openssl-devel
sudo dnf config-manager --disable epel
sudo dnf --enablerepo=epel -y update epel-release
# CodeReady Builder (CRB) repo name differs by EL version: EL8=powertools, EL9+=crb
source /etc/os-release
if [ "${VERSION_ID%%.*}" -ge 9 ]; then
  CRB_REPO=crb
else
  CRB_REPO=powertools
fi
# libxml2-devel/libxslt-devel/zlib-devel は AL8 で nokogiri をネイティブビルドする際に使用
# (AL8 は glibc 2.28 のためプリコンパイル gem の GLIBC_2.29 要求を満たせない)。AL9+ では無害。
sudo dnf -y --enablerepo=epel,${CRB_REPO} install ImageMagick ImageMagick-devel git wget libyaml-devel mecab mecab-devel mecab-ipadic libxml2-devel libxslt-devel zlib-devel

cat <<EOS | sudo tee /etc/yum.repos.d/mongodb-org-8.0.repo > /dev/null
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=0
gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
EOS

sudo dnf install -y --enablerepo=mongodb-org-8.0 mongodb-org
sudo systemctl enable mongod.service --now

# asdf のパスを確認する関数
check_asdf_installed() {
  if command -v asdf >/dev/null 2>&1; then
    echo "asdf がインストールされています。"
    return 0
  else
    echo "asdf がインストールされていません。"
    return 1
  fi
}

# asdf のインストール（すでにクローン済みかチェック）
if [ ! -d /usr/local/asdf ]; then
  echo "Cloning asdf..."
  sudo git clone --branch v0.15.0 https://github.com/asdf-vm/asdf.git /usr/local/asdf
  if [ $? -ne 0 ]; then
    echo "asdf のクローンに失敗しました。"
    exit 1
  fi
else
  echo "asdf は既にインストールされています。"
fi

# root ユーザーの場合の処理
if [ "$SS_USER" = "root" ]; then
  echo "root ユーザーでは実行できませんが、スクリプトは続行します。"
else
  echo "処理を続行します..."
  # グループが存在しない場合は作成
  if ! getent group asdf >/dev/null; then
    sudo groupadd asdf
  fi

  # /usr/local/asdf の権限設定
  sudo chgrp -R asdf /usr/local/asdf
  sudo chmod -R g+rwXs /usr/local/asdf

  # ユーザーをグループに追加
  sudo usermod -aG asdf "$SS_USER"

  # /usr/local/asdf の所有者とグループを変更
  sudo chown -R "$SS_USER":asdf /usr/local/asdf
fi

# asdf の環境設定ファイルを作成
if [ ! -f /etc/profile.d/asdf.sh ]; then
  echo "Creating /etc/profile.d/asdf.sh..."
  echo 'export ASDF_DIR=/usr/local/asdf
export ASDF_DATA_DIR=$ASDF_DIR

ASDF_BIN="${ASDF_DIR}/bin"
ASDF_USER_SHIMS="${ASDF_DATA_DIR}/shims"
PATH="${ASDF_BIN}:${ASDF_USER_SHIMS}:${PATH}"

. "${ASDF_DIR}/asdf.sh"
. "${ASDF_DIR}/completions/asdf.bash"
' | sudo tee /etc/profile.d/asdf.sh >/dev/null

  if [ $? -ne 0 ]; then
    echo "/etc/profile.d/asdf.sh の作成に失敗しました。"
    exit 1
  fi
else
  echo "/etc/profile.d/asdf.sh は既に存在しています。"
fi

source /etc/profile.d/asdf.sh

export SS_HOSTNAME=${1:-"example.jp"}
export SS_USER=${2:-"$USER"}
export SS_DIR=/var/www/shirasagi
export PORT_COMPA=8001
export PORT_CHILD=8002
export PORT_OPEND=8003
export PORT_LPSPL=8004

check_asdf_installed() {
  if command -v asdf >/dev/null 2>&1; then
    return 0 # `asdf` コマンドが存在する場合、成功を示すステータスコード 0 を返します。
  else
    return 1 # `asdf` コマンドが存在しない場合、失敗を示すステータスコード 1 を返します。
  fi
}

# asdf コマンドの確認
if ! check_asdf_installed; then
  echo "asdf コマンドが利用できません。シェルの設定をリロードして再度確認します。"
  # シェルの設定ファイルをリロード
  exec bash -c "source /etc/profile.d/asdf.sh && echo '再度確認: $(command -v asdf)'; exec bash"
  # exec "$0" "$@"
fi

# asdf プラグインと言語のインストール
echo "Installing asdf plugins and languages..."
asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
asdf install ruby 3.3.9
asdf global ruby 3.3.9

if ! command -v ruby >/dev/null; then
  echo 'Rubyのインストールに失敗しました'
  exit 1
fi

asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs 24.8.0
asdf global nodejs 24.8.0

if ! command -v node >/dev/null; then
  echo 'Node.js のインストールに失敗しました'
  exit 1
fi

npm install -g yarn
if [ $? -ne 0 ]; then
  echo 'Yarn のインストールに失敗しました'
  exit 1
fi

echo "すべてのインストールが完了しました。"

# MeCab本体・辞書はパッケージで導入済み(上部の dnf install: mecab mecab-devel mecab-ipadic)。
# ふりがな用の Ruby 拡張(mecab-ruby)は SHIRASAGI クローン後に同梱 vendor から構築する(後述)。

#### Voice

cd
wget http://downloads.sourceforge.net/hts-engine/hts_engine_API-1.08.tar.gz \
  http://downloads.sourceforge.net/open-jtalk/open_jtalk-1.07.tar.gz \
  http://downloads.sourceforge.net/lame/lame-3.99.5.tar.gz \
  http://downloads.sourceforge.net/sox/sox-14.4.1.tar.gz

cd
tar xvzf hts_engine_API-1.08.tar.gz
cd hts_engine_API-1.08
./configure
make
sudo make install
#cd
#sudo mv hts_engine_API-1.08 /usr/local/src

cd
tar xvzf open_jtalk-1.07.tar.gz
cd open_jtalk-1.07
sed -i "s/#define MAXBUFLEN 1024/#define MAXBUFLEN 10240/" bin/open_jtalk.c
sed -i "s/0x00D0 SPACE/0x000D SPACE/" mecab-naist-jdic/char.def
./configure --with-charset=UTF-8
make
sudo make install
#cd
#sudo mv open_jtalk-1.07 /usr/local/src

cd
tar xvzf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure
make
sudo make install
#cd
#sudo mv lame-3.99.5 /usr/local/src

cd
tar xvzf sox-14.4.1.tar.gz
cd sox-14.4.1
./configure
make
sudo make install
#cd
#sudo mv sox-14.4.1 /usr/local/src

sudo ldconfig

echo "Creating /var/www directory..."
sudo mkdir -p /var/www
if [ $? -ne 0 ]; then
  echo "Failed to create /var/www directory."
  exit 1
fi

# Shirasagi のインストール
cd
git clone -b stable https://github.com/shirasagi/shirasagi
if [ $? -ne 0 ]; then
  echo "Shirasagi のクローンに失敗しました。"
  exit 1
fi

# クローンした shirasagi ディレクトリを移動
echo "Moving shirasagi directory to $SS_DIR..."
sudo mv shirasagi "$SS_DIR"
if [ $? -ne 0 ]; then
  echo "Failed to move shirasagi directory to $SS_DIR."
  exit 1
fi

# Shirasagi の設定ファイルをコピー
echo "Changing directory to /var/www/shirasagi..."
cd $SS_DIR
if [ $? -ne 0 ]; then
  echo "ディレクトリの移動に失敗しました。スクリプトを終了します。"
  exit 1
fi

# Gemfile の存在を確認
if [ ! -f "Gemfile" ]; then
  echo "Gemfile が見つかりません。スクリプトを終了します。"
  exit 1
fi

cp -n config/samples/*.{rb,yml} config/
if [ $? -ne 0 ]; then
  echo "設定ファイルのコピーに失敗しました。"
  exit 1
fi

export SS_HOSTNAME=${1:-"example.jp"}
export SS_USER=${2:-"$USER"}
export SS_DIR=/var/www/shirasagi
export PORT_COMPA=8001
export PORT_CHILD=8002
export PORT_OPEND=8003
export PORT_LPSPL=8004

if ! check_asdf_installed; then
  echo "asdf コマンドが利用できません。シェルの設定をリロードして再度確認します。"
  # シェルの設定ファイルをリロード
  exec bash -lc "source /etc/profile.d/asdf.sh && echo '再度確認: $(command -v asdf)'"
fi

# AlmaLinux 8 (glibc 2.28) では nokogiri 等のプリコンパイル gem が GLIBC_2.29 を要求し
# 起動できないため、ネイティブビルド(ruby platform)を強制する。EL9+ (glibc>=2.34) は不要。
source /etc/os-release
if [ "${VERSION_ID%%.*}" -lt 9 ]; then
  echo "AlmaLinux ${VERSION_ID}: force_ruby_platform を有効化（プリコンパイル gem の glibc 非互換を回避）"
  $(asdf which bundle) config set --local force_ruby_platform true
fi

# 絶対パスで bundle install を実行（リトライ付き）
for i in $(seq 1 5); do
  # Bundler を使って依存関係をインストール
  $(asdf which bundle) install

  if [ $? -eq 0 ]; then
    echo "Bundle install succeeded"
    break
  else
    echo "Attempt $i: Bundle install failed, retrying..."
    sleep 5s
  fi

  if [ $i -eq 5 ]; then
    echo "Bundle install が5回失敗しました。スクリプトを終了します。"
    exit 1
  fi
done

echo "セットアップが完了しました。"

# ふりがな(MeCab Ruby拡張): 同梱 vendor から構築。MeCab本体/辞書はパッケージ導入済み。
# 共有ディレクトリ(/usr/local/src)を777にせず、専用の一時ディレクトリでビルドする。
MECAB_BUILD_DIR=$(mktemp -d)
cp -arp "${SS_DIR}/vendor/mecab/mecab-ruby-0.996.tar.gz" "${MECAB_BUILD_DIR}/"
cd "${MECAB_BUILD_DIR}" || exit 1
tar xvzf mecab-ruby-0.996.tar.gz
cd mecab-ruby-0.996 || exit 1
$(asdf which ruby) extconf.rb && make && make install || exit 1
cd "${SS_DIR}" || exit 1
rm -rf "${MECAB_BUILD_DIR}"
cp config/defaults/kana.yml config/
sed -i "s#/usr/local/libexec/mecab/mecab-dict-index#/usr/libexec/mecab/mecab-dict-index#" config/kana.yml
sed -i "s#/usr/local/lib/mecab/dic/ipadic#/usr/lib64/mecab/dic/ipadic#" config/kana.yml

# asdf reshim を実行
echo "asdf reshim を実行しています..."
asdf reshim

# 結果の確認
if [ $? -eq 0 ]; then
  echo "asdf reshim の実行が成功しました。"
else
  echo "エラー: asdf reshim の実行に失敗しました。"
  exit 1
fi
# secret_key_base の credentials 化
# 開発ドキュメントに準拠: config 直下のデフォルト credentials
# （config/master.key + config/credentials.yml.enc）へ格納する。
# --environment は指定しない（指定すると config/credentials/production.* が作られてしまうため）。
# secret_key_base の値は rails secret でランダム生成する（secrets.yml のサンプル固定値は使わない）。
# ref: https://shirasagi.github.io/trouble-shootings/secret_key_base.html
# credentials:edit は対話エディタを起動するため、非対話の一時 EDITOR で
# secret_key_base のみを設定/更新し、無人実行でも失敗しないようにする。
echo "Configuring Rails credentials (secret_key_base)"
SS_SECRET_KEY_BASE=$($(asdf which rails) secret)
export SS_SECRET_KEY_BASE
CRED_EDITOR=$(mktemp)
cat > "${CRED_EDITOR}" <<'CRED_EOF'
#!/usr/bin/env bash
# 既存の credentials 内容を保持し、secret_key_base のみ設定/更新する。
# ($1 は credentials:edit が渡す復号済み YAML の一時ファイルパス)
cred_tmp="$1.new"
grep -v '^secret_key_base:' "$1" > "${cred_tmp}" 2>/dev/null || true
printf 'secret_key_base: %s\n' "${SS_SECRET_KEY_BASE}" >> "${cred_tmp}"
mv "${cred_tmp}" "$1"
CRED_EOF
chmod +x "${CRED_EDITOR}"
EDITOR="${CRED_EDITOR}" $(asdf which rails) credentials:edit
CRED_STATUS=$?
rm -f "${CRED_EDITOR}"

# エラーチェック
if [ ${CRED_STATUS} -ne 0 ]; then
  echo "Error: Encryption of credentials file failed"
  exit 1
else
  echo "Credentials file encrypted successfully"
fi

# secret_key_base の取得
echo "Running: bundle exec rails runner 'puts Rails.application.credentials.secret_key_base'"
$(asdf which bundle) exec rails runner 'puts Rails.application.credentials.secret_key_base'

# config/secrets.yml の削除
if [ -f "config/secrets.yml" ]; then
  echo "Removing config/secrets.yml"
  rm config/secrets.yml
else
  echo "config/secrets.yml does not exist, skipping removal."
fi

#sed -i "s/dbcae379.*$/$(bundle exec rake secret)/" config/secrets.yml

# enable recommendation
#sed -e "s/disable: true$/disable: false/" config/defaults/recommend.yml >config/recommend.yml

sudo systemctl enable firewalld.service --now

sudo firewall-cmd --add-port=http/tcp --permanent
#sudo firewall-cmd --add-port=https/tcp --permanent
#sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --add-port=${PORT_COMPA}/tcp --permanent
sudo firewall-cmd --add-port=${PORT_CHILD}/tcp --permanent
sudo firewall-cmd --add-port=${PORT_OPEND}/tcp --permanent
sudo firewall-cmd --add-port=${PORT_LPSPL}/tcp --permanent
sudo firewall-cmd --reload

#### Furigana

#### Nginx

cat <<EOF | sudo tee /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=0
EOF

sudo dnf -y --enablerepo=nginx install nginx
#sudo nginx -t
sudo systemctl enable nginx.service --now
sudo mkdir -p /var/cache/nginx/proxy_cache

cat <<EOF | sudo tee /etc/nginx/conf.d/http.conf
server_tokens off;
charset utf-8;
server_name_in_redirect off;
etag on;
client_max_body_size 100m;
client_body_buffer_size 256k;
gzip on;
gzip_http_version 1.0;
gzip_comp_level 1;
gzip_proxied any;
gzip_vary on;
gzip_buffers 4 8k;
gzip_min_length 1000;
gzip_types text/plain
           text/xml
           text/css
           text/javascript
           application/xml
           application/xhtml+xml
           application/rss+xml
           application/atom_xml
           application/javascript
           application/x-javascript
           application/x-httpd-php;
gzip_disable "MSIE [1-6]\\.";
gzip_disable "Mozilla/4";
proxy_headers_hash_bucket_size 128;
proxy_headers_hash_max_size 1024;
proxy_cache_path /var/cache/nginx/proxy_cache levels=1:2 keys_zone=my-key:8m max_size=50m inactive=120m;
proxy_temp_path /var/cache/nginx/proxy_temp;
proxy_buffers 8 64k;
proxy_buffer_size 64k;
proxy_max_temp_file_size 0;
proxy_connect_timeout 30;
proxy_read_timeout 120;
proxy_send_timeout 10;
proxy_cache_use_stale timeout invalid_header http_500 http_502 http_503 http_504;
proxy_cache_lock on;
proxy_cache_lock_timeout 5s;
EOF

cat <<EOF | sudo tee /etc/nginx/conf.d/header.conf
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header Remote-Addr \$remote_addr;
proxy_set_header X-Forwarded-Proto \$thescheme;
proxy_set_header X-Forwarded-Host \$http_host;
proxy_set_header X-Forwarded-Server \$host;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header Accept-Encoding "";
proxy_set_header X-Sendfile-Type X-Accel-Redirect;
proxy_hide_header X-Pingback;
proxy_hide_header Link;
proxy_hide_header ETag;
EOF

sudo mkdir /etc/nginx/conf.d/common/
cat <<EOF | sudo tee /etc/nginx/conf.d/common/drop.conf
location = /favicon.ico                      { expires 1h; access_log off; log_not_found off; }
location = /robots.txt                       { expires 1h; access_log off; log_not_found off; }
location = /apple-touch-icon.png             { expires 1h; access_log off; log_not_found off; }
location = /apple-touch-icon-precomposed.png { expires 1h; access_log off; log_not_found off; }
EOF

cat <<EOF | sudo tee /etc/nginx/conf.d/virtual.conf
map \$http_x_forwarded_proto \$thescheme {
    default \$scheme;
    https https;
}
server {
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME};
    root ${SS_DIR}/public/sites/w/w/w/_/;
}
server {
    listen  ${PORT_COMPA};
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:${PORT_COMPA};
    root ${SS_DIR}/public/sites/c/o/m/p/a/n/y/_/;
}
server {
    listen  ${PORT_CHILD};
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:${PORT_CHILD};
    root ${SS_DIR}/public/sites/c/h/i/l/d/c/a/r/e/_/;
}
server {
    listen  ${PORT_OPEND};
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:${PORT_OPEND};
    root ${SS_DIR}/public/sites/o/p/e/n/d/a/t/a/_/;
}
server {
    listen  ${PORT_LPSPL};
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME}:${PORT_LPSPL};
    root ${SS_DIR}/public/sites/l/p/_/_/;
}
EOF

sudo mkdir /etc/nginx/conf.d/server/
cat <<EOF | sudo tee /etc/nginx/conf.d/server/shirasagi.conf
include conf.d/common/drop.conf;
error_page 404 /404.html;
location @app {
    include conf.d/header.conf;
    if (\$request_filename ~ .*\\.(ico|gif|jpe?g|png|css|js)$) { access_log off; }
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header X-Accel-Mapping ${SS_DIR}/=/private_files/;
    proxy_intercept_errors on;
}
location / {
    try_files \$uri \$uri/index.html @app;
}
location /assets/ {
    root ${SS_DIR}/public/;
    expires 1h;
    access_log off;
}
location /private_files/ {
    internal;
    alias ${SS_DIR}/;
}
# download .svg files instead of showing inline in browser for protecting from xss
location ~* \.svg$ {
    expires 1h;
    access_log off;
    log_not_found off;
    add_header Content-Disposition "attachment";
    try_files \$uri @app;
}
# download .htm/html files instead of showing inline in browser for protecting from xss.
# for only belonging to fs directories.
location ~* /fs/.*\.(htm|html)$ {
    add_header Content-Disposition "attachment";
    try_files \$uri @app;
}
EOF

sudo systemctl restart nginx.service

# ディレクトリの確認
if [ -z "$SS_DIR" ]; then
  echo "Error: SS_DIR is not set"
  exit 1
fi
cd "$SS_DIR"

# アセットのプリコンパイル
$(asdf which bundle) exec rake assets:precompile RAILS_ENV=production

# データベース管理
# データベース削除のコマンド
$(asdf which bundle) exec rake db:drop

# インデックス作成
$(asdf which bundle) exec rake db:create_indexes

# サイトの作成
if [ -z "$SS_HOSTNAME" ]; then
  echo "Error: SS_HOSTNAME is not set"
  exit 1
fi

$(asdf which bundle) exec rake ss:create_site data="{ name: \"自治体サンプル\", host: \"www\", domains: \"${SS_HOSTNAME}\" }"
$(asdf which bundle) exec rake ss:create_site data="{ name: \"企業サンプル\", host: \"company\", domains: \"${SS_HOSTNAME}:${PORT_COMPA}\" }"
$(asdf which bundle) exec rake ss:create_site data="{ name: \"子育て支援サンプル\", host: \"childcare\", domains: \"${SS_HOSTNAME}:${PORT_CHILD}\" }"
$(asdf which bundle) exec rake ss:create_site data="{ name: \"オープンデータサンプル\", host: \"opendata\", domains: \"${SS_HOSTNAME}:${PORT_OPEND}\" }"
$(asdf which bundle) exec rake ss:create_site data="{ name: \"ＬＰサンプル\", host: \"lp_\", domains: \"${SS_HOSTNAME}:${PORT_LPSPL}\" }"

# データのシーディング
$(asdf which bundle) exec rake db:seed name=demo site=www
$(asdf which bundle) exec rake db:seed name=company site=company
$(asdf which bundle) exec rake db:seed name=childcare site=childcare
$(asdf which bundle) exec rake db:seed name=opendata site=opendata
$(asdf which bundle) exec rake db:seed name=lp site=lp_
$(asdf which bundle) exec rake db:seed name=gws
$(asdf which bundle) exec rake db:seed name=webmail

# CMS ノードとページの生成
$(asdf which bundle) exec rake cms:generate_nodes
$(asdf which bundle) exec rake cms:generate_pages

# MongoDB での OpenLayers API 設定
if command -v mongosh &>/dev/null; then
  echo 'db.ss_sites.update({}, { $set: { map_api: "openlayers" } }, { multi: true });' | mongosh ss >/dev/null
else
  echo "Error: MongoDB is not installed or not available in the PATH"
  exit 1
fi

cat <<EOF | crontab
*/15 * * * * /bin/bash -l -c 'cd ${SS_DIR}; /usr/bin/flock -x -w 10 ${SS_DIR}/tmp/cms_release_nodes_lock bundle exec rake cms:release_nodes; /usr/bin/flock -x -w 10 ${SS_DIR}/tmp/cms_release_pages_lock bundle exec rake cms:release_pages; /usr/bin/flock -x -w 10 ${SS_DIR}/tmp/cms_generate_nodes_lock bundle exec rake cms:generate_nodes' >/dev/null
0 * * * * /bin/bash -l -c 'cd ${SS_DIR}; /usr/bin/flock -x -w 10 ${SS_DIR}/tmp/cms_generate_pages_lock bundle exec rake cms:generate_pages' >/dev/null
EOF

# modify ImageMagick policy to work with simple captcha
# see: https://github.com/diaspora/diaspora/issues/6828
cd /etc/ImageMagick-6 && cat <<EOF | sudo patch
--- policy.xml.orig     2016-12-08 13:50:47.344009000 +0900
+++ policy.xml  2016-12-08 13:15:22.529009000 +0900
@@ -67,6 +67,8 @@
   <policy domain="coder" rights="none" pattern="MVG" />
   <policy domain="coder" rights="none" pattern="MSL" />
   <policy domain="coder" rights="none" pattern="TEXT" />
-  <policy domain="coder" rights="none" pattern="LABEL" />
+  <!-- <policy domain="coder" rights="none" pattern="LABEL" /> -->
   <policy domain="path" rights="none" pattern="@*" />
+  <policy domain="coder" rights="read | write" pattern="JPEG" />
+  <policy domain="coder" rights="read | write" pattern="PNG" />
 </policymap>
EOF

# Puma を SHIRASAGI 標準の方法で自動起動設定する（開発マニュアル installation/puma.html 準拠）。
# 公式同梱の bin/puma.service をそのまま /etc/systemd/system/puma.service へ配置し、
# User のみ実行ユーザに調整する。WorkingDirectory/PIDFile は /var/www/shirasagi 前提で一致。
# WEB_CONCURRENCY / RAILS_MAX_THREADS / PUMA_RAM / PUMA_ROLLING_RESTART_FREQUENCY 等の
# チューニング用 Environment（一部コメントアウト）は公式ユニットのまま保持し、マニュアルの
# 性能調整手順（コメント解除で調整）がそのまま使えるようにする。
sudo cp -n "${SS_DIR}/bin/puma.service" /etc/systemd/system/puma.service
sudo sed -i "s/^User=.*/User=${SS_USER}/" /etc/systemd/system/puma.service
# 公式サンプルの ExecStop シグナル名の誤字 TERN を TERM に修正（systemctl stop を有効にする）
sudo sed -i "s/kill -TERN /kill -TERM /" /etc/systemd/system/puma.service
sudo chown root: /etc/systemd/system/puma.service
sudo chmod 644 /etc/systemd/system/puma.service
sudo systemctl daemon-reload
sudo systemctl enable puma --now

exit
