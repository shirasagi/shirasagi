module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

    included do

      field :twitter_auto_post,   type: String, metadata: { branch: false }
      field :facebook_auto_post,  type: String, metadata: { branch: false }
      field :sns_auto_delete,     type: String, metadata: { branch: false }
      field :edit_auto_post,      type: String, metadata: { branch: false }
      field :twitter_user_id,     type: String, metadata: { branch: false }
      field :twitter_post_id,     type: String, metadata: { branch: false }
      field :facebook_user_id,    type: String, metadata: { branch: false }
      field :facebook_post_id,    type: String, metadata: { branch: false }
      field :twitter_posted,      type: Array, default: [], metadata: { branch: false }
      field :facebook_posted,     type: Array, default: [], metadata: { branch: false }
      field :twitter_post_error,  type: String, metadata: { branch: false }
      field :facebook_post_error, type: String, metadata: { branch: false }

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
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def twitter_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def sns_auto_delete_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def edit_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def fb_message_format(html)
      s = @cur_site || site

      postfix = ''
      if s.facebook_appends_here_state == 'show'
        postfix = "\n"
        postfix += (s.facebook_appends_here_prefix.presence || s.facebook_appends_here_prefix_default)
        postfix += full_url
      end

      max = s.facebook_max_text_length || 253
      max -= postfix.length
      return postfix if max <= 0

      html = ActionController::Base.helpers.strip_tags(html)
      ActionController::Base.helpers.truncate(html, length: max) + postfix
    end

    def use_twitter_post?
      twitter_auto_post == "active"
    end

    def use_facebook_post?
      facebook_auto_post == "active"
    end

    def sns_auto_delete_enabled?
      sns_auto_delete == "active"
    end

    def edit_auto_post_enabled?
      edit_auto_post == "active"
    end

    def twitter_url(post_id, user_id)
      "https://twitter.com/#{user_id}/status/#{post_id}" if
        use_twitter_post? && user_id.present? && post_id.present?
    end

    def facebook_url(post_id, user_id)
      "https://www.facebook.com/#{user_id}/posts/#{post_id}" if \
        use_facebook_post? && user_id.present? && post_id.present?
    end

    def twitter_post_enabled?
      return false unless use_twitter_post?
      return true if edit_auto_post_enabled?
      return false if twitter_posted.present?
      true
    end

    def facebook_post_enabled?
      return false unless use_facebook_post?
      return true if edit_auto_post_enabled?
      return false if facebook_posted.present?
      true
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

    private

    def post_sns
      return if @posted_sns

      # tweet
      post_to_twitter if twitter_post_enabled?

      # facebook
      post_to_facebook if facebook_post_enabled?

      @posted_sns = true
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
      self.add_to_set(twitter_posted: { twitter_post_id: twitter_id.to_s, twitter_user_id: user_screen_id })
      self.unset(:twitter_post_error)
    rescue => e
      Rails.logger.fatal("post_to_twitter failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      self.set(twitter_post_error: "#{e.class} (#{e.message})")
    end

    def post_to_facebook
      message = fb_message_format(html)
      access_token = self.site.facebook_access_token
      graph = Koala::Facebook::API.new(access_token)
      # facebokに投稿し、戻り値を取得
      facebook_params = graph.put_wall_post(message, { "link" => full_url })
      facebook_param = facebook_params['id'].to_s
      # 戻り値からUID/PID取得し、DBに保存
      facebook_id_array = facebook_id_separator(facebook_param)
      self.set(facebook_user_id: facebook_id_array[0], facebook_post_id: facebook_id_array[1])
      self.add_to_set(facebook_posted: { facebook_user_id: facebook_id_array[0], facebook_post_id: facebook_id_array[1] })
      self.unset(:facebook_post_error)
    rescue => e
      Rails.logger.fatal("post_to_facebook failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      self.set(facebook_post_error: "#{e.class} (#{e.message})")
    end

    def delete_sns
      return if @deleted_sns

      if sns_auto_delete_enabled?
        delete_sns_from_twitter
        delete_sns_from_facebook
      end

      @deleted_sns = true
    end

    def delete_sns_from_twitter
      return if twitter_posted.blank?

      client = connect_twitter
      twitter_posted.each do |posted|
        post_id = posted[:twitter_post_id]
        client.destroy_status(post_id) rescue nil
      end
      self.unset(:twitter_post_id, :twitter_user_id, :twitter_posted, :twitter_post_error) rescue nil
    rescue => e
      Rails.logger.fatal("delete_sns_from_twitter failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      self.set(twitter_post_error: "#{e.class} (#{e.message})")
    end

    def delete_sns_from_facebook
      return if facebook_posted.blank?

      access_token = self.site.facebook_access_token
      graph = Koala::Facebook::API.new(access_token)
      # UID_PIDの形式に組み替え、投稿を削除
      facebook_posted.each do |posted|
        post_id = posted[:facebook_post_id]
        user_id = posted[:facebook_user_id]
        graph.delete_object("#{user_id}_#{post_id}") rescue nil
      end
      self.unset(:facebook_user_id, :facebook_post_id, :facebook_posted, :facebook_post_error) rescue nil
    rescue => e
      Rails.logger.fatal("delete_sns_from_facebook failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      self.set(facebook_post_error: "#{e.class} (#{e.message})")
    end
  end
end
