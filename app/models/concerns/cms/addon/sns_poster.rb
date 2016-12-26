module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :fbauto,     type: String, default: 'expired'
      field :twauto,     type: String, default: 'expired'
      field :deleteauto, type: String, default: 'expired'
      field :twid, type: String
      field :fbid, type: String
      permit_params :fbauto, :twauto, :deleteauto, :twid, :fbid
      after_generate_file { post_sns() }
      after_remove_file { delete_sns() }
    end

    def sns_poster_fb_options
      [
        [I18n.t('views.options.state.active'), 'active'],
        [I18n.t('views.options.state.expired'), 'expired'],
      ]
    end

    def sns_poster_fb_options_ja
      I18n.t("views.options.state.#{fbauto}")
    end

    def sns_poster_tw_options
      [
        [I18n.t('views.options.state.active'), 'active'],
        [I18n.t('views.options.state.expired'), 'expired'],
      ]
    end

    def sns_poster_tw_options_ja
      I18n.t("views.options.state.#{twauto}")
    end

    def sns_poster_delete_options
      [
        [I18n.t('views.options.state.active'), 'active'],
        [I18n.t('views.options.state.expired'), 'expired'],
      ]
    end

    def sns_poster_delete_options_ja
      I18n.t("views.options.state.#{deleteauto}")
    end

    private
      def post_sns
        site_name = "自治体サンプル"
        tweet_url = "http://localhost:3000#{url}"

        # tweet
        if twauto === "active"
          require 'twitter'
          client = Twitter::REST::Client.new do |config|
            config.consumer_key        = 'xxxxxxxxxxxxxxxxx'
            config.consumer_secret     = 'xxxxxxxxxxxxxxxxx'
            config.access_token        = 'xxxxxxxxxxxxxxxxx'
            config.access_token_secret = 'xxxxxxxxxxxxxxxxx'
          end
          tweet = "#{name}｜#{tweet_url}"
          twitter_param = client.update(tweet)
          twitter_id = twitter_param.id
          self.update(twid: twitter_id)

        end

        # facebook
        if fbauto === "active"
          require 'koala'
          access_token = 'EAACEdEose0cBAD0Cn4c5qLTtIh5ls3aw2vY9FErHTVJpZCntyHIY42xl0Qe3GHGwwGj3tqM0swHPTlmoeciKVmjzMZBlNUk4sKwYjFmH9JsPg0iilFb19DkZA5VTBRsRZAiMptzxvXIVptjBOQSdxpxN17UfPUeKJl1ezJMYZCgZDZD'
          graph = Koala::Facebook::API.new(access_token)
          facebook_param = graph.put_wall_post("ホームページを更新しました。", {
            "name" => "#{name} - #{site_name}",
            # 有効なurlでないとエラーになるようなので、ダミーデータを代入
            "link" => "http://www.google.co.jp/",
            "description" => "#{name}"
            # "link" => "#{tweet_url}",
            # "description" => "#{name}"
          })
          facebook_param = facebook_param['id'].inspect
          self.update(fbid: facebook_param)
          logger.error fbid
        end
      end

      def delete_sns
        if deleteauto === "active"
        end
      end
  end
end
