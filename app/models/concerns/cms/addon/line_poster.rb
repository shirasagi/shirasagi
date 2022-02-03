module Cms::Addon
  module LinePoster
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :skip_line_post

      field :line_auto_post, type: String
      field :line_edit_auto_post, type: String

      field :line_posted, type: Array, default: [], metadata: { branch: false }
      field :line_post_error, type: String, metadata: { branch: false }

      field :line_text_message, type: String
      field :line_post_format, type: String

      validate :validate_line_postable, if: -> { line_auto_post == "active" }

      permit_params :line_auto_post, :line_edit_auto_post, :line_text_message, :line_post_format

      after_save -> { post_to_line(execute: :job) }
    end

    def line_auto_post_options
      %w(expired active).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def line_post_format_options
      %w(thumb_carousel body_carousel message_only_carousel).map { |v| [I18n.t("cms.options.line_post_format.#{v}"), v] }
    end

    def line_edit_auto_post_options
      %w(disabled enabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def use_line_post?
      line_auto_post == "active"
    end

    def line_edit_auto_post_enabled?
      line_edit_auto_post == "enabled"
    end

    def line_post_enabled?
      token_enabled = (site || @cur_site).try(:line_poster_enabled?)

      return false if !token_enabled
      return false if skip_line_post.present?
      return false if !use_line_post?
      return false if respond_to?(:branch?) && branch?

      if line_edit_auto_post_enabled?
        # 再編集が有効の為、すでに投稿済みかをチェックしない。
      else
        return false if line_posted.present?
      end

      true
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

    def post_to_line(execute: :inline)
      return unless public?
      return unless public_node?
      return if @posted_to_line

      if line_post_enabled?
        if execute == :job
          Cms::SnsPost::LineJob.bind(site_id: @cur_site, user_id: @cur_user).perform_later(id)
        else
          execute_post_to_line
        end
      end

      @posted_to_line = true
    end

    private

    def validate_line_postable
      policy = SS::UploadPolicy.upload_policy
      if policy
        msg = I18n.t("errors.messages.denied_with_upload_policy", policy: I18n.t("ss.options.upload_policy.#{policy}"))
        errors.add :base, "#{t(:line_auto_post)}：#{msg}"
        return
      end

      if name.present? && name.size > 40
        errors.add :name, :too_long_with_line_title, count: 40
      end
      if line_post_format == "thumb_carousel" && thumb.blank?
        errors.add :thumb_id, :blank
      end
      if line_text_message.present?
        if line_text_message.index("\n")
          errors.add :line_text_message, :invalid_new_line_included
        end
        if line_text_message.size > 45
          errors.add :line_text_message, :too_long, count: 45
        end
      else
        errors.add :line_text_message, :blank
      end
    end

    def execute_post_to_line
      Cms::SnsPostLog::Line.create_with(self) do |log|
        begin
          posted_at = Time.zone.now
          log.created = posted_at
          log.action = "broadcast"

          messages = []
          if line_post_format == "thumb_carousel"
            messages << line_message_carousel(thumb.try(:full_url))
          elsif line_post_format == "body_carousel"
            messages << line_message_carousel(first_img_full_url)
          elsif line_post_format == "message_only_carousel"
            messages << line_message_carousel
          end
          raise "messages blank" if messages.blank?
          log.messages = messages

          res = site.line_client.broadcast(messages)
          log.response_code = res.code
          log.response_body = res.body
          raise "#{res.code} #{res.body}" if res.code != "200"

          self.add_to_set(line_posted: posted_at)
          self.unset(:line_edit_auto_post, :line_post_error) #編集時に投稿をリセット
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
        title: name,
        text: line_text_message.to_s,
        actions: [
          {
            type: "uri",
            label: I18n.t("cms.visit_article"),
            uri: full_url
          }
        ]
      }

      if thumb_url.present?
        column["thumbnailImageUrl"] = thumb_url
        column["imageBackgroundColor"] = "#FFFFFF"
      end

      {
        type: "template",
        altText: name,
        template: {
          type: "carousel",
          columns: [column]
        }
      }
    end
  end
end
