module Cms::Addon
  module TwitterPoster
    extend ActiveSupport::Concern
    include Cms::Content
    extend SS::Addon

    # media_ids is restricted up to 4
    # see: https://developer.twitter.com/en/docs/tweets/post-and-engage/api-reference/post-statuses-update
    TWITTER_MAX_MEDIA_COUNT = 4

    included do
      attr_accessor :skip_twitter_post

      field :twitter_auto_post, type: String
      field :twitter_post_format, type: String
      field :twitter_edit_auto_post, type: String

      field :twitter_posted, type: Array, default: [], metadata: { branch: false }
      field :twitter_post_error, type: String, metadata: { branch: false }

      permit_params :twitter_auto_post, :twitter_edit_auto_post, :twitter_post_format, :twitter_post_id, :twitter_user_id

      validate :validate_twitter_postable, if: -> { twitter_auto_post == "active" }

      after_save -> { post_to_twitter(execute: :job) }
    end

    def twitter_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def twitter_post_format_options
      I18n.t("cms.options.twitter_post_format").map { |k, v| [v, k] }
    end

    def twitter_edit_auto_post_options
      %w(disabled enabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def use_twitter_post?
      twitter_auto_post == "active"
    end

    def twitter_edit_auto_post_enabled?
      twitter_edit_auto_post == "enabled"
    end

    def twitter_url(post_id, user_id)
      "https://twitter.com/#{user_id}/status/#{post_id}" if
        use_twitter_post? && user_id.present? && post_id.present?
    end

    def twitter_post_enabled?
      token_enabled = (site || @cur_site).try(:twitter_poster_enabled?)

      return false if !token_enabled
      return false if skip_twitter_post.present?
      return false if !use_twitter_post?
      return false if respond_to?(:branch?) && branch?

      if twitter_edit_auto_post_enabled?
        # 再編集が有効の為、すでに投稿済みかをチェックしない。
      else
        return false if twitter_posted.present?
      end

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

    def post_to_twitter(execute: :inline)
      return unless public?
      return unless public_node?
      return if @posted_to_twitter

      if twitter_post_enabled?
        if execute == :job
          Cms::SnsPost::TwitterJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(id)
        else
          execute_post_to_twitter
        end
      end

      @posted_to_twitter = true
    end

    private

    def validate_twitter_postable
      policy = SS::UploadPolicy.upload_policy
      if policy
        msg = I18n.t("errors.messages.denied_with_upload_policy", policy: I18n.t("ss.options.upload_policy.#{policy}"))
        errors.add :base, "#{t(:twitter_auto_post)}：#{msg}"
        return
      end

      if twitter_post_format == "thumb_and_page" && thumb.blank?
        errors.add :thumb_id, :blank
      end
    end

    def execute_post_to_twitter
      Cms::SnsPostLog::Twitter.create_with(self) do |log|
        begin
          posted_at = Time.zone.now
          log.created = posted_at

          message = "#{name}｜#{full_url}?_=#{posted_at.to_i}"
          client = connect_twitter
          media_files = tweet_media_files

          if media_files.present?
            # 画像の添付があれば update_with_media を用いて投稿
            log.action = "update_with_media"
            log.message = message
            log.media_files = media_files.map(&:path)
            tweet = client.update_with_media(message, media_files)
          else
            # 画像の添付がなければ update を用いて投稿
            log.action = "update"
            log.message = message
            tweet = client.update(message)
          end
          twitter_id = tweet.id
          user_screen_id = client.user.screen_name
          log.response_tweet = tweet.to_h.to_json

          self.add_to_set(
            twitter_posted: {
              twitter_post_id: twitter_id.to_s,
              twitter_user_id: user_screen_id,
              posted_at: posted_at
            }
          )
          self.unset(:twitter_edit_auto_post, :twitter_post_error) #編集時に投稿をリセット
          log.state = "success"
        rescue => e
          Rails.logger.fatal("post_to_twitter failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          log.error = "post_to_twitter failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
          self.set(twitter_post_error: "#{e.class} (#{e.message})")
        end
      end
    end

    def tweet_media_files
      media_files = []
      if twitter_post_format == "thumb_and_page" && thumb
        media_files << thumb
      elsif twitter_post_format == "files_and_page"
        media_files = attached_files.select(&:image?).take(TWITTER_MAX_MEDIA_COUNT)
      end
      media_files.map { |file| ::File.new(file.path) }
    end
  end
end
