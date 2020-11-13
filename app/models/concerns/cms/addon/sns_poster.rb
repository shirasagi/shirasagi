module Cms::Addon
  module SnsPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

    # media_ids is restricted up to 4
    # see: https://developer.twitter.com/en/docs/tweets/post-and-engage/api-reference/post-statuses-update
    TWITTER_MAX_MEDIA_COUNT = 4

    included do

      field :twitter_auto_post,   type: String, metadata: { branch: false }
      field :twitter_user_id,     type: String, metadata: { branch: false }
      field :twitter_post_id,     type: String, metadata: { branch: false }
      field :sns_auto_delete,     type: String, metadata: { branch: false }
      field :edit_auto_post,      type: String, metadata: { branch: false }
      field :twitter_posted,      type: Array, default: [], metadata: { branch: false }
      field :twitter_post_error,  type: String, metadata: { branch: false }

      permit_params :twitter_auto_post,
                    :sns_auto_delete,
                    :edit_auto_post,
                    :twitter_post_id,
                    :twitter_user_id

      after_save :post_sns
      after_remove_file :delete_sns
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

    def use_twitter_post?
      twitter_auto_post == "active"
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

    def twitter_post_enabled?
      return false unless use_twitter_post?
      return true if edit_auto_post_enabled?
      return false if twitter_posted.present?
      true
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
      return unless public?
      return unless public_node?
      return if @posted_sns

      # tweet
      post_to_twitter if twitter_post_enabled?

      @posted_sns = true
    end

    def post_to_twitter
      tweet = "#{name}｜#{full_url}"
      client = connect_twitter
      media_files = []
      # 画像の添付を収集
      attached_files.each do |file|
        next if !file.image?
        media_files << ::File.new(file.path)
        break if media_files.length >= TWITTER_MAX_MEDIA_COUNT
      end
      if media_files.present?
        # 画像の添付があれば update_with_media を用いて投稿
        twitter_param = client.update_with_media(tweet, media_files)
      else
        # 画像の添付がなければ update を用いて投稿
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
    ensure
      if media_files.present?
        media_files.each do |file|
          file.close rescue nil
        end
      end
    end

    def delete_sns
      return if @deleted_sns

      if sns_auto_delete_enabled?
        delete_sns_from_twitter
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
  end
end
