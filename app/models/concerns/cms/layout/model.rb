# coding: utf-8
module Cms::Layout::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include Cms::Page::Feature
  include Cms::Addon::Html

  included do
    store_in collection: "cms_layouts"
    set_permission_name "cms_layouts"

    field :part_paths, type: SS::Extensions::Words, metadata: { form: :none }
    field :css_paths, type: SS::Extensions::Words, metadata: { form: :none }
    field :js_paths, type: SS::Extensions::Words, metadata: { form: :none }

    before_save :set_part_paths
    before_save :set_css_paths
    before_save :set_js_paths
    after_save :rename_file, if: ->{ @db_changes }
    after_save :generate_file, if: ->{ @db_changes }
    after_save :remove_file, if: ->{ @db_changes && @db_changes["state"] && !public? }
    after_destroy :remove_file
  end

  public
    def render_html
      html = self.html.to_s.gsub(/<\/ part ".+?" \/>/).each do |m|
        path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : dirname(path)

        part = Cms::Part
        part = part.where(site_id: site_id, filename: path).first
        part = part.becomes_with_route if part
        part ? part.render_html : "<!-- #{path} -->"
      end
    end

    def render_json(html = render_html)
      head = (html =~ /<head>/) ? html.sub(/^.*?<head>(.*?)<\/head>.*/im, "\\1") : ""
#      head.scan(/<link [^>]*href="([^"]*\.css)" [^>]*\/>/).uniq.each do |m|
#        if (path = m[0]).index("//")
#          head.gsub!(/"#{path}"/, "\"#{path}?_=$now\"") if path !~ /\?/
#        elsif SS.config.cms.serve_static_layouts
#          head.gsub!(/"#{path}"/, "\"#{path}?_=$now\"") if path !~ /\?/
#        else
#          file  = "#{site.path}#{path}"
#          data  = Fs.stat(file).mtime.to_s rescue ""
#          data << Fs.stat(file.sub(/\.css$/, ".scss")).mtime.to_s rescue ""
#          head.gsub!(/"#{path}"/, "\"#{path}?_=#{Digest::MD5.hexdigest(data)}\"")
#        end
#      end

      body = (html =~ /<body/) ? html.sub(/^.*?(<body.*<\/body>).*/im, "\\1") : ""

      href = head.scan(/ (?:src|href)="(.*?)"/).map {|m| m[0]}.uniq.sort.join(",") rescue nil
      href = Digest::MD5.hexdigest href

      { head: head, body: body, href: href }.to_json
    end

    def generate_file
      return unless public?
      Cms::Task::LayoutsController.new.generate_file(self)
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

    def rename_file
      return unless @db_changes["filename"]
      return unless @db_changes["filename"][0]

      src = "#{site.path}/#{@db_changes['filename'][0]}"
      dst = "#{site.path}/#{@db_changes['filename'][1]}"
      Fs.mv src, dst if Fs.exists?(src)

      src.sub!(/\.html$/, '.json')
      dst.sub!(/\.html$/, '.json')
      Fs.mv src, dst if Fs.exists?(src)
    end

    def remove_file
      Fs.rm_rf path
      Fs.rm_rf json_path
    end
end
