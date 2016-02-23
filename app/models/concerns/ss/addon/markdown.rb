module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      permit_params :text
    end

    def html
      Kramdown::Document.new(text).to_html
    end
  end
end
