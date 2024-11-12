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

WORKDIR "/workspaces/shirasagi"
RUN bundle config set --local path vendor/bundle
RUN bundle install --jobs 4

RUN tar xzf vendor/mecab/mecab-ruby-0.996.tar.gz && \
    cd mecab-ruby-0.996 && \
    bundle exec ruby extconf.rb && \
    make && \
    make install && \
    cd .. && \
    rm -rf mecab-ruby-0.996

RUN cp config/samples/mongoid.yml config/mongoid.yml

RUN bundle exec rake db:create_indexes
RUN bundle exec rake ss:create_site data="{ name: '自治体サンプル', host: 'www', domains: 'www.example.jp:3000', mypage_domain: 'localhost:3000', map_api: 'openlayers' }"
RUN bundle exec rake ss:create_site data="{ name: '企業サンプル', host: 'company', domains: 'company.example.jp:3000', mypage_domain: 'localhost:3000', map_api: 'openlayers' }"
RUN bundle exec rake ss:create_site data="{ name: '子育て支援サンプル', host: 'childcare', domains: 'childcare.example.jp:3000', mypage_domain: 'localhost:3000', map_api: 'openlayers' }"
RUN bundle exec rake ss:create_site data="{ name: 'オープンデータ', host: 'opendata', domains: 'www.example.jp:3000', mypage_domain: 'localhost:3000', map_api: 'openlayers', subdir: 'opendata', parent_id: 1 }"
RUN bundle exec rake ss:create_site data="{ name: 'LPサンプル', host: 'lp_', domains: 'lp.example.jp:3000', mypage_domain: 'localhost:3000', map_api: 'openlayers' }"

RUN bundle exec rake db:seed site=www name=demo
RUN bundle exec rake db:seed site=company name=company
RUN bundle exec rake db:seed site=childcare name=childcare
RUN bundle exec rake db:seed site=opendata name=opendata
RUN bundle exec rake db:seed site=lp_ name=lp
RUN bundle exec rake db:seed name=gws
RUN bundle exec rake db:seed name=webmail

RUN bundle exec rake cms:set_subdir_url site=opendata

RUN find public/sites/ -name '*.html' -delete
