module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      field :text_type, type: String
      permit_params :text, :text_type
    end

    def text_type_options
      [:plain, :markdown].map { |m| [I18n.t("views.options.text_type.#{m}"), m] }
    end

    def html
      return nil if text.blank?
      if text_type == 'markdown'
        Kramdown::Document.new(text, input: 'GFM').to_html
      else
        text.gsub(/(\r\n?)|(\n)/, "<br />")
      end
    end
  end
end
