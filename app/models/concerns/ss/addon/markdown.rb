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
        if text.blank?
          self.html = nil
        else
          markdown = ::Redcarpet::Markdown.new Redcarpet::Render::HTML, autolink: true, tables: true
          self.html = markdown.render(text)
        end
      end
  end
end
