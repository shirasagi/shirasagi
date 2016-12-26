module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

    included do

      field :twitter_auto_post,  type: String, default: 'expired'
      field :facebook_auto_post, type: String, default: 'expired'
      field :sns_auto_delete,    type: String, default: 'expired'
      field :twitter_user_id,    type: String
      field :twitter_post_id,    type: String
      field :facebook_user_id,   type: String
      field :facebook_post_id,   type: String

      permit_params :facebook_auto_post,
                    :twitter_auto_post,
                    :sns_auto_delete,
                    :twitter_post_id,
                    :twitter_user_id,
                    :facebook_user_id,
                    :facebook_post_id

      after_generate_file { post_sns }
      after_remove_file { delete_sns }
    end

    def sns_poster_facebook_options
      definition_state
    end

    def sns_poster_facebook_options_ja
      I18n.t("views.options.state.#{facebook_auto_post}")
    end

    def sns_poster_twitter_options
      definition_state
    end

    def sns_poster_twitter_options_ja
      I18n.t("views.options.state.#{twitter_auto_post}")
    end

    def sns_poster_delete_options
      definition_state
    end

    def sns_poster_delete_options_ja
      I18n.t("views.options.state.#{sns_auto_delete}")
    end

    def site_url
      "#{site.url}#{filename}/"
    end

    def site_full_url
      "#{site.full_url}#{filename}/"
    end

    def access_token_facebook(snskeys)
      access_token = snskeys["access_token_facebook"]
      graph = Koala::Facebook::API.new(access_token)
    end

    def image_path
      if file_ids.present?
        files_info = []
        image_paths = []
        files_info = Article::Page.find(_id).files
        files_info.each do |file_info|
          image_paths << file_info.full_url
        end
        image_paths
      end
    end

    def message_format(html)
      html = ActionController::Base.helpers.strip_tags(html)
      html = ActionController::Base.helpers.truncate(html, :length=> 253)
    end

    def use_twitter_post?
      twitter_auto_post == "active"
    end

    def use_facebook_post?
      facebook_auto_post == "active"
    end

    def twitter_url
      "https://twitter.com/#{twitter_user_id}/status/#{twitter_post_id}" if use_twitter_post?
    end

    def facebook_url
      "https://www.facebook.com/#{facebook_user_id}/posts/#{facebook_post_id}" if use_facebook_post?
    end

    def facebook_id_separator(facebook_param)
      facebook_id_array = facebook_param.split("_")
    end

    def connect_twitter(snskeys)
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
        image_param = []
        site_name = site.name
        message = message_format(html)
        snskeys = SS.config.cms.sns_poster

        # tweet
        if use_twitter_post?
          tweet = "#{name}｜#{site_full_url}"
          client = connect_twitter(snskeys)
          # 画像の添付があればuploadとupdateを用いて投稿
            if file_ids.present?
              i = 0
              image_path.each do |image_code|
                image_param << client.upload(open_from_url(image_code))
                i += 1
                break if i >= 4
              end
              twitter_param = client.update( tweet, { "media_ids"=> image_param.join(',') } )
          # 画像の添付がなければupdateを用いて投稿
            else
              twitter_param = client.update(tweet)
            end
          # 戻り値から投稿IDを取得し、DBに保存
            twitter_id = twitter_param.id
            self.set(twitter_post_id: twitter_id)
          # URLを表示するためにスクリーンネームを取得し、DBに保存
            user_screen_id = client.user.screen_name
            self.set(twitter_user_id: user_screen_id)
        end

        # facebook
        if use_facebook_post?
          if file_ids.present?
            image_path = image_path.first
          end
          graph = access_token_facebook(snskeys)
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
          # 戻り値からUID/PID取得し、DBに保存
            facebook_id_array = facebook_id_separator(facebook_param)
            self.set(facebook_user_id: facebook_id_array[0])
            self.set(facebook_post_id: facebook_id_array[1])
        end
      end

      def delete_sns
        snskeys = SS.config.cms.sns_poster
        if sns_auto_delete == "active"
          if twitter_post_id.present?
            client = connect_twitter(snskeys)
            client.destroy_status(twitter_post_id)
          end
          if facebook_post_id.present?
            graph = access_token_facebook(snskeys)
            # UID_PIDの形式に組み替え、投稿を削除
              graph.delete_object("#{facebook_user_id}_#{facebook_post_id}")
          end
        end
      end

      def definition_state
        [
          [I18n.t('views.options.state.active'), 'active'],
          [I18n.t('views.options.state.expired'), 'expired'],
        ]
      end
  end
end
