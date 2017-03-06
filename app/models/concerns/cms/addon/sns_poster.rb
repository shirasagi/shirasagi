module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

   require 'twitter'

    included do
      field :fbauto,     type: String, default: 'expired'
      field :twauto,     type: String, default: 'expired'
      field :deleteauto, type: String, default: 'expired'
      field :twid, type: String
      field :twuid, type: String
      field :fbid, type: String
      field :fbuid, type: String
      field :fbpid, type: String
      field :fburl, type: String
      permit_params :fbauto, :twauto, :deleteauto, :twid, :twuid, :fbid, :fbuid, :fbpid, :fburl
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

    def site_url
      "#{site.url}#{filename}/"
    end

    def site_full_url
      "#{site.full_url}#{filename}/"
    end

    def image_path
      image_ids = file_ids.to_a.first.to_s.split("").join("/")
      "#{site.full_url}fs/" + image_ids + "/_/#{filename}"
    end

    def tw_url
      if twauto == "active"
        "https://twitter.com/#{twuid}/status/#{twid}"
      end
    end

    def fb_url
      if fbauto == "active"
        fburl
      end
    end

    def fbid_separator(facebook_param)
      fbidArray = facebook_param.split("_")
    end

    def twSnskeys(snskeys)
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = snskeys["consumer_key"]
        config.consumer_secret     = snskeys["consumer_secret"]
        config.access_token        = snskeys["access_token"]
        config.access_token_secret = snskeys["access_token_secret"]
      end
    end

    private
      def post_sns
        site_name = site.name
        message = ActionController::Base.helpers.strip_tags(html)
        tweet_url = "http://localhost:3000#{site_url}"
        if file_ids.present?
          image_url_for_sns = file_ids
        end
        snskeys = SS.config.cms.sns_poster

        # tweet
        if twauto === "active"
          client = twSnskeys(snskeys)
          tweet = "#{name}｜#{tweet_url}"
          twitter_param = client.update(tweet)
          twitter_id = twitter_param.id
          self.set(twid: twitter_id)
          user_screen_id = client.user.screen_name
          self.set(twuid: user_screen_id)
        end

        # facebook
        if fbauto === "active"
          require 'koala'
          access_token = snskeys["access_token_f"]
          graph = Koala::Facebook::API.new(access_token)
          facebook_param = graph.put_wall_post( message, {
            "name" => "#{name} - #{site_name}",
            # 有効なurlでないとエラーになるようなので、ダミーデータを代入
            "link" => "http://www.google.co.jp/",
            # 本来はこっち
            # "link" => site_full_url,
            "description" => "#{description}"
          })
          facebook_param = facebook_param['id'].to_s
          self.set(fbid: facebook_param)

          # UID/PID取得
          fbidArray = fbid_separator(facebook_param)
          
          self.set(fbuid: fbidArray[0])
          self.set(fbpid: fbidArray[1])

          fbinfo = graph.get_object('me?fields=link')
          self.set(fburl: fbinfo['link'].to_s)

          logger.error "site_url=>"
          logger.error site_url
          logger.error "site_full_url=>"
          logger.error site_full_url
          logger.error "file_ids=>"
          logger.error file_ids.to_a.first
          logger.error "image_path=>"
          logger.error image_path
          logger.error "site=>"
          logger.error site.inspect

        end
      end

      def delete_sns
        snskeys = SS.config.cms.sns_poster
        if deleteauto === "active"
          if twid.present?
            client = twSnskeys(snskeys)
            client.destroy_status(twid)
          end
          if fbid.present?
            require 'koala'
            access_token = snskeys["access_token_f"]
            graph = Koala::Facebook::API.new(access_token)
            graph.delete_object(fbid)
          end
        end
      end
  end
end
