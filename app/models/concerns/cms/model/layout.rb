module Cms::Model::Layout
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Content

  attr_accessor :keywords, :description

  included do
    store_in collection: "cms_layouts"
    set_permission_name "cms_layouts"

    field :part_paths, type: SS::Extensions::Words
    field :css_paths, type: SS::Extensions::Words
    field :js_paths, type: SS::Extensions::Words

    before_save :set_part_paths
    before_save :set_css_paths
    before_save :set_js_paths
  end

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

  # returns admin side show path
  def private_show_path(*args)
    model = self.class.name.underscore.sub(/^.+?\//, "")
    options = args.extract_options!
    methods = []
    if parent.blank?
      options = options.merge(site: site || cur_site, id: self)
      methods << "cms_#{model}_path"
    else
      options = options.merge(site: site || cur_site, cid: parent, id: self)
      methods << "node_#{model}_path"
    end

    helper_mod = Rails.application.routes.url_helpers
    methods.each do |method|
      path = helper_mod.send(method, *args, options) rescue nil
      return path if path.present?
    end

    nil
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

  def set_css_paths
    self.css_paths = html.to_s.scan(/<link [^>]*href="([^"]*\.css)" [^>]*\/>/).map { |m| m[0] }.uniq
  end

  def set_js_paths
    self.js_paths = html.to_s.scan(/<script [^>]*src="([^"]*\.js)"[^>]*>/).map { |m| m[0] }.uniq
  end
end
