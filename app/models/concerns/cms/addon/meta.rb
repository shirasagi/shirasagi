module Cms::Addon
  module Meta
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :keywords, type: SS::Extensions::Words
      field :description, type: String
      field :summary_html, type: String
      field :description_setting, type: String
      permit_params :keywords, :description, :summary_html, :description_setting

      before_save :set_keywords, if: ->{ @cur_site && @cur_site.auto_keywords_enabled? }
      before_save :set_description, if: ->{ @cur_site && @cur_site.auto_description_enabled? }

      if respond_to? :template_variable_handler
        template_variable_handler :summary, :template_variable_handler_name
        template_variable_handler :description, :template_variable_handler_description
      end
      if respond_to? :liquidize
        liquidize do
          export :summary
          export :template_variable_handler_description, as: :description
        end
      end
    end

    def summary
      return summary_html if summary_html.present?
      return nil unless respond_to?(:html)

      html = self.try(:render_html).presence || self.html
      return nil if html.blank?

      html = ApplicationController.helpers.sanitize(html, tags: [])
      return nil if html.blank?

      html = Cms.unescape_html_entities(html)
      html = html.squish
      html = html.truncate(120)
      html.html_safe
    end

    def meta_present?
      [keywords, description, summary_html].map(&:present?).any?
    end

    def description_setting_manual?
      description_setting == 'manual'
    end

    def description_setting_auto?
      !description_setting_manual?
    end

    private

    def set_keywords
      return if keywords.present?

      keywords = []
      keywords << (parent ? parent.name : @cur_site.name)
      categories.each { |cate| keywords << cate.name }
      keywords += @cur_site.keywords.to_a
      self.keywords = keywords.uniq.join(", ")
    end

    def set_description
      return if description.present?
      return unless respond_to?(:html)
      html = self.try(:render_html).presence || self.html
      self.description = ApplicationController.helpers.
        sanitize(html.to_s, tags: []).squish.truncate(60)
    end

    def template_variable_handler_description(*_)
      Rails.logger.debug "=== template_variable_handler_description start ==="
      Rails.logger.debug "description_setting_auto?: #{description_setting_auto?}"
      Rails.logger.debug "current description: #{description}"

      return description unless description_setting_auto?
      Rails.logger.debug "auto mode: proceeding with HTML processing"

      html = self.try(:render_html).presence || self.try(:html)
      Rails.logger.debug "html content: #{html}"
      return description if html.blank?

      # HTMLからテキストを抽出し、descriptionを生成
      text = ApplicationController.helpers.sanitize(html.to_s, tags: [])
      Rails.logger.debug "after sanitize: #{text}"

      text = Cms.unescape_html_entities(text)
      Rails.logger.debug "after unescape: #{text}"

      text = text.squish
      Rails.logger.debug "after squish: #{text}"

      result = text.truncate(60)
      Rails.logger.debug "final result: #{result}"
      Rails.logger.debug "=== template_variable_handler_description end ==="

      result
    end
  end
end
