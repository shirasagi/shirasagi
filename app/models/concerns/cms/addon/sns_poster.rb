module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

   require 'twitter'
   require 'koala'

    included do
      field :fbauto,     type: String, default: 'expired'
      field :twauto,     type: String, default: 'expired'
      field :deleteauto, type: String, default: 'expired'

      # twuid…ツイッター＊ユーザID
        field :twuid, type: String
      # twid…ツイッター＊投稿ID
        field :twid, type: String
      # fbuid…フェイスブック＊ユーザID
        field :fbuid, type: String
      # fbpid…フェイスブック＊投稿ID
        field :fbpid, type: String

      permit_params :fbauto, :twauto, :deleteauto, :twid, :twuid, :fbuid, :fbpid
      after_generate_file { post_sns }
      after_remove_file { delete_sns }
    end

    def dammy_data?
      true
    end

    def sns_poster_fb_options
      definition_state
    end

    def sns_poster_fb_options_ja
      I18n.t("views.options.state.#{fbauto}")
    end

    def sns_poster_tw_options
      definition_state
    end

    def sns_poster_tw_options_ja
      I18n.t("views.options.state.#{twauto}")
    end

    def sns_poster_delete_options
      definition_state
    end

    def sns_poster_delete_options_ja
      I18n.t("views.options.state.#{deleteauto}")
    end

    def definition_state
      [
        [I18n.t('views.options.state.active'), 'active'],
        [I18n.t('views.options.state.expired'), 'expired'],
      ]
    end

    def site_url
      "#{site.url}#{filename}/"
    end

    def site_full_url
      "#{site.full_url}#{filename}/"
    end

    def access_token_f(snskeys)
      access_token = snskeys["access_token_f"]
      graph = Koala::Facebook::API.new(access_token)
    end

    def image_path
      if file_ids.present?
        image_paths = Article::Page.find(_id).files.first.full_url
        logger.error "image_paths =>"
        logger.error image_paths
      end
    end

    def message_format(html)
      html = ActionController::Base.helpers.strip_tags(html)
      html = ActionController::Base.helpers.truncate(html, :length=> 253)
    end

    def tw_url
      if twauto == "active"
        "https://twitter.com/#{twuid}/status/#{twid}"
      end
    end

    def fb_url
      if fbauto == "active"
        "https://www.facebook.com/#{fbuid}/posts/#{fbpid}"
      end
    end

    def fbid_separator(facebook_param)
      fbid_array = facebook_param.split("_")
    end

    def tw_snskeys(snskeys)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = snskeys["consumer_key"]
        config.consumer_secret     = snskeys["consumer_secret"]
        config.access_token        = snskeys["access_token"]
        config.access_token_secret = snskeys["access_token_secret"]
      end
    end

    def open_from_url(image_url)
      image_file = open(image_url)
      return image_file unless image_file.is_a?(StringIO)
      file_name = File.basename(image_url)
      temp_file = Tempfile.new(file_name)
      temp_file.binmode
      temp_file.write(image_file.read)
      temp_file.close
      open(temp_file.path)
    end

    private
      def post_sns
        site_name = site.name
        message = message_format(html)
        snskeys = SS.config.cms.sns_poster

        #　localhostで動かすなど、ダミーデータが必要な状況下であればダミーデータを代入
        if dammy_data?
          site_full_url = "http://www.google.co.jp/"
          if file_ids.present?
            image_path = "http://fmbee.com/image/i_02.jpg"
          end
        end

        # tweet
        if twauto == "active"
          tweet = "#{name}｜#{site_full_url}"
          # アクセストークンを用いてTwitterに接続
            client = tw_snskeys(snskeys)
          # 画像の添付がればupdate_with_mediaを用いて投稿
            if file_ids.present?
              twitter_param = client.update_with_media(tweet, open_from_url(image_path))
          # 画像の添付がなければupdateを用いて投稿
            else
              twitter_param = client.update(tweet)
            end
          # 戻り値から投稿IDを取得し、DBに保存
            twitter_id = twitter_param.id
            self.set(twid: twitter_id)
          # URLを表示するためにスクリーンネームを取得し、DBに保存
            user_screen_id = client.user.screen_name
            self.set(twuid: user_screen_id)
        end

        # facebook
        if fbauto == "active"
          # アクセストークンを用いてfacebookに接続
            graph = access_token_f(snskeys)
          # facebokに投稿し、戻り値を取得
            facebook_params = graph.put_wall_post(
              message,
              {
                "name"=> "#{name} - #{site_name}",
                "link"=> site_full_url,
                "picture"=> image_path,
                "description"=> description
              }
            )
            facebook_param = facebook_params['id'].to_s
          # 戻り値からUID/PID取得
            fbid_array = fbid_separator(facebook_param)
          # UID/PIDをDBへ保存
            self.set(fbuid: fbid_array[0])
            self.set(fbpid: fbid_array[1])
        end
      end

      def delete_sns
        snskeys = SS.config.cms.sns_poster
        if deleteauto == "active"
          if twid.present?
          # アクセストークンを用いてTwitterに接続
            client = tw_snskeys(snskeys)
          # 投稿IDをもとに、投稿を削除
            client.destroy_status(twid)
          end
          if fbpid.present?
            # アクセストークンを用いてfacebookに接続
              graph = access_token_f(snskeys)
            # UID_PIDの形式に組み替え、投稿を削除
              graph.delete_object("#{fbuid}_#{fbpid}")
          end
        end
      end
  end
end
