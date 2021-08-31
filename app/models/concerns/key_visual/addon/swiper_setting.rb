# Swiper を利用したスライドパーツ
#
# Swiper にはさまざまな機能がありますが、すでにサイトは v6.8.0 向けになっており、
# シラサギに組み込んだ v4.5.1 の情報を閲覧するにはドキュメント・リポジトリをダウンロードし、
# ローカルで起動する必要があります。ドキュメント・サーバーをローカルで起動する方法をコメントに残しておきます。
#
# 1. git clone "https://github.com/nolimits4web/swiper-website.git"
# 2. cd swiper-website
# 3. git checkout -b v4.5.1 7c39459f845de33fe759348ad9e271f2b1da9863
# 4. npm install
# 5 ./node_modules/.bin/gulp build
# 6. swiper-website ディレクトリを VS Code で開き "Go Live"（機能拡張のインストールの必要あり）で HTTP サーバーを起動します。
#    起動するとドキュメントがブラウザに表示されます。
# 6-1. ./node_modules/.bin/gulp server を実行すると 3000 ポートで HTTP サーバーが起動します。
#      ブラウザで http://localhost:3000/ にアクセスすることでもドキュメントを表示させることができます。
#
module KeyVisual::Addon::SwiperSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  DEFAULT_KV_SPEED = 500
  DEFAULT_KV_PAUSE = 4_000
  DEFAULT_KV_THUMBNAIL_COUNT = 4

  included do
    field :link_target, type: String
    field :kv_speed, type: Integer
    field :kv_space, type: Integer
    field :kv_autoplay, type: String
    field :kv_pause, type: Integer
    field :kv_navigation, type: String
    field :kv_pagination_style, type: String
    field :kv_thumbnail, type: String
    field :kv_thumbnail_count, type: Integer

    permit_params :link_target, :kv_speed, :kv_space, :kv_autoplay, :kv_pause, :kv_navigation, :kv_pagination_style
    permit_params :kv_thumbnail, :kv_thumbnail_count

    validates :link_target, inclusion: { in: %w(_blank), allow_blank: true }
    validates :kv_autoplay, inclusion: { in: %w(disabled enabled started), allow_blank: true }
    validates :kv_navigation, inclusion: { in: %w(hide show), allow_blank: true }
    validates :kv_pagination_style, inclusion: { in: %w(none disc number), allow_blank: true }
    validates :kv_thumbnail, inclusion: { in: %w(hide show), allow_blank: true }
  end

  def link_target_options
    [
      [I18n.t('key_visual.options.link_target.self'), ''],
      [I18n.t('key_visual.options.link_target.blank'), '_blank'],
    ]
  end

  def kv_autoplay_options
    %w(disabled enabled started).map do |v|
      [ I18n.t("key_visual.options.autoplay.#{v}"), v ]
    end
  end

  def kv_navigation_options
    %w(hide show).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def kv_pagination_style_options
    %w(none disc number).map do |v|
      [ I18n.t("key_visual.options.pagination_style.#{v}"), v ]
    end
  end

  def kv_thumbnail_options
    %w(hide show).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def js_option
    option = {
      speed: kv_speed || DEFAULT_KV_SPEED, space: kv_space, autoplay: kv_autoplay, pause: kv_pause || DEFAULT_KV_PAUSE,
      navigation: kv_navigation, pagination_style: kv_pagination_style,
      thumbnail: kv_thumbnail, thumbnail_count: kv_thumbnail_count || DEFAULT_KV_THUMBNAIL_COUNT
    }
    if Rails.env.test?
      option[:test] = true
    end
    option
  end
end
