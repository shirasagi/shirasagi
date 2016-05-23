module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      permit_params :text
    end

    def html
      return nil if text.blank?
      Kramdown::Document.new(text, input: 'GFM').to_html
    end
  end
end
