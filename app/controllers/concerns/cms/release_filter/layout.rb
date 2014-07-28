# coding: utf-8
module Cms::ReleaseFilter::Layout
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter

  private
    def find_layout(path)
      layout = Cms::Layout.site(@cur_site).find_by(filename: path) rescue nil
      return nil unless layout
      @preview || layout.public? ? layout : nil
    end

    def render_layout(layout)
      @cur_layout = layout
      respond_to do |format|
        format.html { layout.render_html }
        format.json { layout.render_json }
      end
    end

    def send_layout(body)
      respond_to do |format|
        format.html do
          body.sub!(/(<[^>]+ id="ss-site-name".*?>)[^<]*/, "\\1#{@cur_site.name}")
          body.sub!(/(<[^>]+ id="ss-page-name".*?>)[^<]*/, "\\1Layout")
          render inline: body
        end
        format.json { render json: body }
      end
    end

    def generate_layout(layout)
      return unless SS.config.cms.serve_static_layouts

      html = layout.render_html
      keep = html.to_s == File.read(layout.path).to_s rescue false

      Fs.write layout.path, html
      Fs.write layout.json_path, layout.render_json
    end

    def find_part(path)
      part = Cms::Part.site(@cur_site).find_by(filename: path) rescue nil
      return unless part
      @preview || part.public?  ? part : nil
    end

    def render_part(part, path = @path)
      return part.html if part.route == "cms/frees"
      cell = recognize_path "/.#{@cur_site.host}/parts/#{part.route}.#{path.sub(/.*\./, '')}"
      return unless cell
      @cur_part = part
      render_cell part.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
    end

    def send_part(body)
      respond_to do |format|
        format.html { render inline: body, layout: (request.xhr? ? false : "cms/part") }
        format.json { render json: body.to_json }
      end
    end

    def embed_layout(body, layout, opts = {})
      meta = (m = body.match(/(.*?)<\/head>/m)) ? m[1] : nil
      head = body.match(/<header.*?<\/header>/m).to_s
      site_name = head =~ /<[^>]+ id="ss-site-name".*?>(.*?)</m ? $1 : nil
      page_name = head =~ /<[^>]+ id="ss-page-name".*?>(.*?)</m ? $1 : nil

      if layout
        @request_url = "/#{@path}"

        html = layout.html.to_s.gsub(/<\/ part ".+?" \/>/) do |m|
          path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
          path = path[0] == "/" ? path.sub(/^\//, "") : layout.dirname(path)

          part = Cms::Part.site(@cur_site)
          part = part.where opts[:part_condition] if opts[:part_condition]
          part = part.where(filename: path).first
          part = part.becomes_with_route if part
          part ? render_part(part, path) : ""
        end

        main = body =~ /<!-- yield -->(.*)<!-- \/yield -->/m ? $1 : body
        body = html.sub(/<\/ yield \/>/, main)

        body.sub!(/(<[^>]+ id="ss-site-name".*?>)[^<]*/, "\\1#{site_name}")
        body.sub!(/(<[^>]+ id="ss-page-name".*?>)[^<]*/, "\\1#{page_name}")
        body.sub!(/.*?<head>/m, meta) if meta
      end

      body.sub!("</body>", %Q[<script> $(function(){ SS.load(); }) </script></body>])

      body
    end
end
