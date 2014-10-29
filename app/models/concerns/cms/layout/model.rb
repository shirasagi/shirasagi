module Cms::Layout::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content
  include Cms::Addon::Html
  include History::Addon::Backup

  attr_accessor :keywords, :description

  included do
    store_in collection: "cms_layouts"
    set_permission_name "cms_layouts"

    field :part_paths, type: SS::Extensions::Words, metadata: { form: :none }
    field :css_paths, type: SS::Extensions::Words, metadata: { form: :none }
    field :js_paths, type: SS::Extensions::Words, metadata: { form: :none }

    before_save :set_part_paths
    before_save :set_css_paths
    before_save :set_js_paths
  end

  public
    def head
      return nil if html !~ /<head>/
      tags = []
      tags << %(<meta name="keywords" content="#{keywords}" />) if keywords.present?
      tags << %(<meta name="description" content="#{description}" />) if description.present?
      tags << self.html.sub(/.*?<head>(.*)<\/head>.*/im, '\\1')
      tags.join("\n")
    end

    def body
      return html =~ /<body/ ? html.sub(/.*?(<body.*<\/body>).*/im, '\\1') : nil
    end

  private
    def fix_extname
      ".layout.html"
    end

    def set_part_paths
      return true if html.blank?

      paths = html.scan(/<\/ part ".+?" \/>/).map do |m|
        path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : dirname(path)
      end
      self.part_paths = paths.uniq
    end

    def  set_css_paths
      self.css_paths = html.to_s.scan(/<link [^>]*href="([^"]*\.css)" [^>]*\/>/).map {|m| m[0] }.uniq
    end

    def  set_js_paths
      self.js_paths = html.to_s.scan(/<script [^>]*src="([^"]*\.js)"[^>]*>/).map {|m| m[0] }.uniq
    end
end
