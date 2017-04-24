module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

    included do

      field :twitter_auto_post,  type: String
      field :facebook_auto_post, type: String
      field :sns_auto_delete,    type: String
      field :edit_auto_post,     type: String
      field :twitter_user_id,    type: String
      field :twitter_post_id,    type: String
      field :facebook_user_id,   type: String
      field :facebook_post_id,   type: String

      permit_params :facebook_auto_post,
                    :twitter_auto_post,
                    :sns_auto_delete,
                    :edit_auto_post,
                    :twitter_post_id,
                    :twitter_user_id,
                    :facebook_user_id,
                    :facebook_post_id

      after_generate_file { post_sns }
      after_remove_file { delete_sns }
    end

    def facebook_auto_post_options
      [
        [I18n.t('views.options.sns_poster.none'), 'none'],
        [I18n.t('views.options.sns_poster.active'), 'active'],
        [I18n.t('views.options.sns_poster.expired'), 'expired'],
      ]
    end

    def twitter_auto_post_options
      [
        [I18n.t('views.options.sns_poster.none'), 'none'],
        [I18n.t('views.options.sns_poster.active'), 'active'],
        [I18n.t('views.options.sns_poster.expired'), 'expired'],
      ]
    end

    def sns_auto_delete_options
      [
        [I18n.t('views.options.sns_poster.none'), 'none'],
        [I18n.t('views.options.sns_poster.active'), 'active'],
        [I18n.t('views.options.sns_poster.expired'), 'expired'],
      ]
    end

    def edit_auto_post_options
      [
        [I18n.t('views.options.sns_poster.none'), 'none'],
        [I18n.t('views.options.sns_poster.active'), 'active'],
        [I18n.t('views.options.sns_poster.expired'), 'expired'],
      ]
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
      "https://twitter.com/#{twitter_user_id}/status/#{twitter_post_id}" if \
        use_twitter_post? && twitter_user_id.present? && twitter_post_id.present?
    end

    def facebook_url
      "https://www.facebook.com/#{facebook_user_id}/posts/#{facebook_post_id}" if \
        use_facebook_post? && facebook_user_id.present? && facebook_post_id.present?
    end

    def facebook_id_separator(facebook_param)
      facebook_param.split("_")
    end

    def connect_twitter
      Twitter::REST::Client.new do |config|
        config.consumer_key        = self.site.twitter_consumer_key
        config.consumer_secret     = self.site.twitter_consumer_secret
        config.access_token        = self.site.twitter_access_token
        config.access_token_secret = self.site.twitter_access_token_secret
      end
    end

    def twitter_token_enabled?
      @cur_site.twitter_consumer_key.present? && @cur_site.twitter_consumer_secret.present? && \
      @cur_site.twitter_access_token.present? && @cur_site.twitter_access_token_secret.present?
    end

    def facebook_token_enabled?
      @cur_site.facebook_access_token.present?
    end

    private
      def post_sns_twitter
        if use_twitter_post?
          post_to_twitter
        elsif twitter_auto_post == "none"
          if @cur_node.node_twitter_auto_post_enabled?
            post_to_twitter
          elsif @cur_node.node_twitter_auto_post == "none"
            site.site_twitter_auto_post_enabled? ? post_to_twitter : nil
          end
        end
      end

      def post_sns_facebook
        if use_facebook_post?
          post_to_facebook
        elsif facebook_auto_post == "none"
          if @cur_node.node_twitter_auto_post_enabled?
            post_to_facebook
          elsif @cur_node.node_twitter_auto_post == "none"
            site.site_twitter_auto_post_enabled? ? post_to_facebook : nil
          end
        end
      end

      def sns_auto_delete_enabled?
        if sns_auto_delete == "active"
          return "active"
        elsif sns_auto_delete == "none"
          if @cur_node.node_sns_auto_delete_enabled?
            return "active"
          elsif @cur_node.node_sns_auto_delete == "none"
            site.site_sns_auto_delete_enabled? ? "active" : nil
          end
        end
      end

      def post_sns_edit
        if edit_auto_post == "active"
          return "active"
        elsif edit_auto_post == "none"
          if @cur_node.node_edit_auto_post == "active"
            return "active"
          elsif @cur_node.node_edit_auto_post == "none"
            site.site_edit_auto_post_enabled? ? "active" : nil
          end
        end
      end

      def post_sns
        # tweet
        if twitter_token_enabled?
          twitter_post_id.nil? || post_sns_edit ? post_sns_twitter : nil
        end

        # facebook
        if facebook_token_enabled?
          facebook_post_id.nil? || post_sns_edit ? post_sns_facebook : nil
        end
      end

      def post_to_twitter
        tweet = "#{name}｜#{full_url}"
        client = connect_twitter
        image_param = []
        # 画像の添付があればuploadとupdateを用いて投稿
        if file_ids.present?
          i = 0
          files.each do |file|
            open(file.path, 'rb') do |f|
              image_param << client.upload(f)
            end
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
        # URLを表示するためにスクリーンネームを取得し、DBに保存
        user_screen_id = client.user.screen_name
        self.set(twitter_post_id: twitter_id, twitter_user_id: user_screen_id)
      rescue => e
        Rails.logger.fatal("post_to_twitter failed: #{e.backtrace.join("\n  ")}")
      end

      def post_to_facebook
        message = message_format(html)
        file_ids.present? ? image_path = files.first.full_url : nil
        access_token = self.site.facebook_access_token
        graph = Koala::Facebook::API.new(access_token)
        # facebokに投稿し、戻り値を取得
        facebook_params = graph.put_wall_post(
          message, {
            "name"=> "#{name} - #{site.name}",
            "link"=> full_url,
            "picture"=> image_path,
            "description"=> description
          }
        )
        facebook_param = facebook_params['id'].to_s
        # 戻り値からUID/PID取得し、DBに保存
        facebook_id_array = facebook_id_separator(facebook_param)
        self.set(facebook_user_id: facebook_id_array[0], facebook_post_id: facebook_id_array[1])
      rescue => e
        Rails.logger.fatal("post_to_facebook failed: #{e.backtrace.join("\n  ")}")
      end

      def delete_sns
        if sns_auto_delete_enabled?
          if twitter_post_id.present?
            client = connect_twitter
            client.destroy_status(twitter_post_id)
            self.set(twitter_post_id: nil, twitter_user_id: nil) rescue nil
          end
          if facebook_post_id.present?
            access_token = self.site.facebook_access_token
            graph = Koala::Facebook::API.new(access_token)
            # UID_PIDの形式に組み替え、投稿を削除
            graph.delete_object("#{facebook_user_id}_#{facebook_post_id}")
            self.set(facebook_user_id: nil, facebook_post_id: nil) rescue nil
          end
        end
      rescue => e
        Rails.logger.fatal("delete_sns failed: #{e.backtrace.join("\n  ")}")
      end
  end
end
