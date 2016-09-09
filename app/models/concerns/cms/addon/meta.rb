module Cms::Addon
  module Meta
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :keywords, type: SS::Extensions::Words
      field :description, type: String
      field :summary_html, type: String
      permit_params :keywords, :description, :summary_html

      before_save :set_keywords, if: ->{ @cur_site && @cur_site.auto_keywords_enabled? }
      before_save :set_description, if: ->{ @cur_site && @cur_site.auto_description_enabled? }

      if respond_to? :template_variable_handler
        template_variable_handler :summary, :template_variable_handler_name
        template_variable_handler :description, :template_variable_handler_name
      end
    end

    def summary
      return summary_html if summary_html.present?
      return nil unless respond_to?(:html)
      ApplicationController.helpers.sanitize(html.presence || '', tags: []).squish.truncate(120)
    end

    def meta_present?
      [keywords, description, summary_html].map(&:present?).any?
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
        self.description = ApplicationController.helpers.
          sanitize(html.to_s, tags: []).squish.truncate(60)
      end
  end
end
