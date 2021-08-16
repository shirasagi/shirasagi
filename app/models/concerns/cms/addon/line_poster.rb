module Cms::Addon
  module LinePoster
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :skip_line_post

      field :line_auto_post, type: String
      field :line_posted, type: Array, default: [], metadata: { branch: false }
      field :line_post_error, type: String, metadata: { branch: false }

      field :line_text_message, type: String
      field :line_post_format, type: String

      validates :line_text_message, presence: true, if: -> { line_auto_post == "active" }
      validates :thumb_id, presence: true, if: -> { line_auto_post == "active" && line_post_format == "thumb_carousel" }
      validate :validate_line_title, if: -> { line_auto_post == "active" && name.present? }
      validate :validate_line_text_message, if: -> { line_text_message.present? }

      permit_params :line_auto_post, :line_text_message, :line_post_format

      after_save :post_to_line
    end

    def line_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def line_post_format_options
      %w(thumb_carousel body_carousel message_only_carousel).map { |v| [I18n.t("cms.options.line_post_format.#{v}"), v] }
    end

    def line_post_enabled?
      token_enabled = (site || @cur_site).try(:line_token_enabled?)

      return false if !token_enabled
      return false if skip_line_post.present?
      return false if line_auto_post != "active"
      return false if respond_to?(:branch?) && branch?
      return false if line_posted.present?
      true
    end

    def line_client
      self.site = site || @cur_site
      Line::Bot::Client.new do |config|
        config.channel_secret = site.line_channel_secret
        config.channel_token = site.line_channel_access_token
      end
    end

    def first_img_url
      body = nil
      body = html if respond_to?(:html)
      body = column_values.map(&:to_html).join("\n") if respond_to?(:form) && form
      SS::Html.extract_img_src(body, site.full_root_url)
    end

    def first_img_full_url
      img_url = first_img_url
      return if img_url.blank?
      img_url = ::File.join(site.full_root_url, img_url) if img_url.start_with?('/')
      img_url
    end

    def reset_line_posted!
      return if line_posted.blank?
      Cms::SnsPostLog::Line.create_with(self) do |log|
        log.created = Time.zone.now
        log.action = "reset_line_posted"
        self.set(line_posted: [])
        log.state = "success"
      end
    end

    private

    def validate_line_title
      if name.size > 40
        errors.add :name, :too_long_with_line_title, count: 40
      end
    end

    def validate_line_text_message
      if line_text_message.index("\n")
        errors.add :line_text_message, :invalid_new_line_included
      end
      if line_text_message.size > 45
        errors.add :line_text_message, :too_long, count: 45
      end
    end

    def post_to_line
      return unless public?
      return unless public_node?
      return if @posted_to_line

      execute_post_to_line if line_post_enabled?

      @posted_to_line = true
    end

    def execute_post_to_line
      Cms::SnsPostLog::Line.create_with(self) do |log|
        begin
          posted_at = Time.zone.now
          log.created = posted_at
          log.action = "broadcast"

          client = line_client
          messages = []
          if line_post_format == "thumb_carousel"
            if thumb
              messages << line_message_carousel(thumb.full_url)
            else
              raise I18n.t("errors.messages.thumb_is_blank")
            end
          elsif line_post_format == "body_carousel"
            img_url = first_img_full_url
            if img_url
              messages << line_message_carousel(img_url)
            else
              raise I18n.t("errors.messages.not_found_file_url_in_body")
            end
          elsif line_post_format == "message_only_carousel"
            messages << line_message_carousel
          end
          raise "messages blank" if messages.blank?
          log.messages = messages

          res = client.broadcast(messages)
          log.response_code = res.code
          log.response_body = res.body
          raise "#{res.code} #{res.body}" if res.code != "200"

          self.add_to_set(line_posted: posted_at)
          self.unset(:line_post_error)
          log.state = "success"
        rescue => e
          Rails.logger.fatal("post_to_line failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
          log.error = "post_to_line failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
          self.set(line_post_error: "#{e.class} (#{e.message})")
        end
      end
    end

    def line_message_carousel(thumb_url = nil)
      column = {
        "title": name,
        "text": line_text_message.to_s,
        "actions": [
          {
            "type": "uri",
            "label": I18n.t("cms.visit_article"),
            "uri": full_url
          }
        ]
      }

      if thumb_url.present?
        column["thumbnailImageUrl"] = thumb_url
        column["imageBackgroundColor"] = "#FFFFFF"
      end

      {
        "type": "template",
        "altText": name,
        "template": {
          "type": "carousel",
          "columns": [column]
        }
      }
    end
  end
end
