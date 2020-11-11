module Cms::Addon
  module LinePoster
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :line_auto_post, type: String, metadata: { branch: false }
      field :line_edit_auto_post, type: String, metadata: { branch: false }
      field :line_posted, type: Array, default: [], metadata: { branch: false }
      field :line_post_error,  type: String, metadata: { branch: false }

      field :line_text_message, type: String, metadata: { branch: false }
      field :line_post_format, type: String, metadata: { branch: false }

      validates :line_text_message, length: { maximum: 60 }
      validates :line_text_message, presence: true, if: -> { line_auto_post == "active" }

      permit_params :line_auto_post, :line_edit_auto_post, :line_text_message, :line_post_format

      after_save :post_line_bot
    end

    def line_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def line_edit_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def line_post_format_options
      %w(thumb_carousel body_carousel message_only_carousel).map { |v| [I18n.t("cms.options.line_post_format_options.#{v}"), v] }
    end

    def line_post_enabled?
      self.site = site || @cur_site
      return false if !site.line_token_enabled?
      return false if line_auto_post != "active"
      return false if line_posted.present? && line_edit_auto_post != "active"
      true
    end

    def line_client
      self.site = site || @cur_site
      Line::Bot::Client.new do |config|
        config.channel_secret = site.line_channel_secret
        config.channel_token = site.line_channel_access_token
      end
    end

    private

    def post_line_bot
      return unless public?
      return unless public_node?
      return if @posted_line_bot

      post_to_line if line_post_enabled?

      @posted_line_bot = true
    end

    def post_to_line
      self.site = site || @cur_site
      client = line_client
      messages = []

      if line_post_format == "thumb_carousel"
        if thumb
          messages << line_message_carousel(thumb.full_url)
        else
          raise I18n.t("errors.messages.thumb_is_blank")
        end
      elsif line_post_format == "body_carousel"

        body = nil
        body = html if respond_to?(:html)
        body = column_values.map(&:to_html).join("\n") if respond_to?(:form) && form
        file_url = SS::Html.extract_img_src(body)
        if file_url
          file_url = ::File.join(site.full_root_url, file_url)
          messages << line_message_carousel(file_url)
        else
          raise I18n.t("errors.messages.not_found_file_url_in_body")
        end
      elsif line_post_format == "message_only_carousel"
        messages << line_message_carousel
      end

      raise "messages blank" if messages.blank?

      res = client.broadcast(messages)
      raise "#{res.code} #{res.body}" if res.code != "200"

      self.add_to_set(line_posted: Time.zone.now)
      self.unset(:line_post_error)
    rescue => e
      Rails.logger.fatal("post_to_line failed: #{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      self.set(line_post_error: "#{e.class} (#{e.message})")
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
        ],
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
          "columns": [column],
        }
      }
    end
  end
end
