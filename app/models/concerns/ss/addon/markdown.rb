module SS::Addon
  module Markdown
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :text, type: String
      field :html, type: String
      permit_params :text

      validate :convert_html
    end

    private
      def convert_html
        self.html = ::Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true).
          render(text)
      end
  end
end
