module Cms::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      field :markdown, type: String
      permit_params :html, :markdown
    end

    def html
      if SS.config.cms.html_editor == "markdown"
        Kramdown::Document.new(markdown.to_s).to_html
      else
        self[:html]
      end
    end
  end
end
