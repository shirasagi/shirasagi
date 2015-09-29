module Cms::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :html, type: String
      field :markdown, type: String
      permit_params :html, :markdown

      validate :convert_markdown, if: -> { SS.config.cms.html_editor == "markdown" }
    end

    public
      def markdown2html
        ::Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(markdown)
      end

    private
      def convert_markdown
        self.html = markdown2html
      end
  end
end
