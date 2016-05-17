SS_HOSTNAME=${1:-"example.jp"}
SS_USER=${2:-"$USER"}
SS_DIR=/var/www/shirasagi

cat <<EOS | sudo tee -a /etc/yum.repos.d/CentOS-Base.repo
[mongodb-org-3.0]
name=MongoDB Repository
baseurl=http://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/3.0/x86_64/
gpgcheck=0
enabled=0
EOS

sudo yum install -y --enablerepo=mongodb-org-3.0 mongodb-org
sudo systemctl start mongod.service
sudo systemctl enable mongod.service

sudo yum -y install \
  gcc gcc-c++ glibc-headers \
  openssl-devel readline libyaml-devel readline-devel zlib zlib-devel \
  wget git ImageMagick ImageMagick-devel

for i in $(seq 1 3)
do
  gpg2 --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 5s
done

\curl -sSL https://get.rvm.io | bash -s stable
if [ `whoami` = root ]; then
  RVM_HOME=/usr/local/rvm
else
  RVM_HOME=$HOME/.rvm
fi
export PATH="$PATH:$RVM_HOME/bin"
source $RVM_HOME/scripts/rvm
rvm install 2.3.0
rvm use 2.3.0 --default
gem install bundler

git clone -b stable --depth 1 https://github.com/shirasagi/shirasagi
sudo mkdir -p /var/www
sudo mv shirasagi $SS_DIR

cd $SS_DIR
cp -n config/samples/*.{rb,yml} config/
for i in $(seq 1 5)
do
  bundle install --without development test --path vendor/bundle
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 5s
done

sudo firewall-cmd --add-port=http/tcp --permanent
#sudo firewall-cmd --add-port=https/tcp --permanent
#sudo firewall-cmd --add-port=3000/tcp --permanent
sudo firewall-cmd --reload

#### Furigana

cd
wget http://mecab.googlecode.com/files/mecab-0.996.tar.gz \
  http://mecab.googlecode.com/files/mecab-ipadic-2.7.0-20070801.tar.gz \
  http://mecab.googlecode.com/files/mecab-ruby-0.996.tar.gz \
  https://raw.githubusercontent.com/shirasagi/shirasagi/stable/vendor/mecab/mecab-ipadic-2.7.0-20070801.patch

cd
tar xvzf mecab-0.996.tar.gz
cd mecab-0.996
./configure --enable-utf8-only
make
sudo make install
#cd
#sudo mv mecab-0.996 /usr/local/src

cd
tar xvzf mecab-ipadic-2.7.0-20070801.tar.gz
cd mecab-ipadic-2.7.0-20070801
patch -p1 < ../mecab-ipadic-2.7.0-20070801.patch
./configure --with-charset=UTF-8
make
sudo make install
#cd
#sudo mv mecab-ipadic-2.7.0-20070801 /usr/local/src

cd
tar xvzf mecab-ruby-0.996.tar.gz
cd mecab-ruby-0.996
ruby extconf.rb
make
sudo make install
#cd
#sudo mv mecab-ruby-0.996 /usr/local/src

echo "/usr/local/lib" | sudo tee -a /etc/ld.so.conf
sudo ldconfig

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

#### Nginx

cat << EOF | sudo tee /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=0
enabled=0
EOF

sudo yum -y --enablerepo=nginx install nginx
#sudo nginx -t
sudo systemctl start nginx.service
sudo systemctl enable nginx.service

cat <<EOF | sudo tee /etc/nginx/conf.d/http.conf
server_tokens off;
server_name_in_redirect off;
etag off;
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
server {
    include conf.d/server/shirasagi.conf;
    server_name ${SS_HOSTNAME};
}
EOF

sudo mkdir /etc/nginx/conf.d/server/
cat <<EOF | sudo tee /etc/nginx/conf.d/server/shirasagi.conf
include conf.d/common/drop.conf;
root ${SS_DIR}/public/sites/w/w/w/_/;

location @app {
    include conf.d/header.conf;
    if (\$request_filename ~ .*\\.(ico|gif|jpe?g|png|css|js)$) { access_log off; }
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header X-Accel-Mapping ${SS_DIR}/=/private_files/;
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
EOF

sudo systemctl restart nginx.service

#### daemonize

cat <<EOF | sudo tee /etc/systemd/system/shirasagi-unicorn.service
[Unit]
Description=Shirasagi Unicorn Server
After=mongod.service

[Service]
User=${SS_USER}
WorkingDirectory=${SS_DIR}
ExecStart=${RVM_HOME}/wrappers/default/bundle exec rake unicorn:start
ExecStop=${RVM_HOME}/wrappers/default/bundle exec rake unicorn:stop
Type=forking
PIDFile=${SS_DIR}/tmp/pids/unicorn.pid

[Install]
WantedBy=multi-user.target
EOF
sudo chown root: /etc/systemd/system/shirasagi-unicorn.service
sudo chmod 644 /etc/systemd/system/shirasagi-unicorn.service
sudo systemctl daemon-reload
sudo systemctl enable shirasagi-unicorn.service
sudo systemctl start shirasagi-unicorn.service

cd $SS_DIR
bundle exec rake db:drop
bundle exec rake db:create_indexes
bundle exec rake ss:create_site data="{ name: \"サイト名\", host: \"www\", domains: \"${SS_HOSTNAME}\" }"
bundle exec rake db:seed name=demo site=www

cat <<EOF | crontab -
*/15 * * * * /bin/bash -l -c 'cd $SS_DIR && ${RVM_HOME}/wrappers/default/bundle exec rake cms:release_pages && ${RVM_HOME}/wrappers/default/bundle exec rake cms:generate_nodes' >/dev/null
0 * * * * /bin/bash -l -c 'cd $SS_DIR && ${RVM_HOME}/wrappers/default/bundle exec rake cms:generate_pages' >/dev/null
EOF
