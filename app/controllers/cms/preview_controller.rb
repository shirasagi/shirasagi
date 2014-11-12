class Cms::PreviewController < ApplicationController
  include Cms::BaseFilter
  include Cms::PublicFilter

  before_action :set_group
  before_action :set_path_with_preview, prepend: true
  after_action :render_preview, if: ->{ @file =~ /\.html$/ }

  private
    def set_site
      @cur_site = SS::Site.find_by host: params[:site]
      @preview  = true
    end

    def set_path_with_preview
      @cur_path ||= request.env["REQUEST_PATH"]
      @cur_path.sub!(/^#{cms_preview_path}(\d+)?/, "")
      @cur_path = "index.html" if @cur_path.blank?
      @cur_path = URI.decode(@cur_path)
      @cur_date = params[:preview_date].present? ? Time.parse(params[:preview_date]) : Time.now
    end

    def x_sendfile(file = @file)
      return if file =~ /\.(ht|x)ml$/
      return if file =~ /\.part\.json$/
      super
      return if response.body.present?

      if @cur_path =~ /^\/fs\// # TODO:
        filename = ::File.basename(@cur_path)
        id = ::File.basename ::File.dirname(@cur_path)
        @item = SS::File.find_by id: id, filename: filename
        return send_data @item.read, type: @item.content_type, filename: @item.filename, disposition: :inline
      end
      raise "404" unless Fs.exists?(file)
    end

    def render_preview
      preview_url = cms_preview_path preview_date: params[:preview_date]

      body = response.body
      body.gsub!(/(href|src)=".*?"/) do |m|
        url = m.match(/.*?="(.*?)"/)[1]
        if url =~ /^\/(assets|assets-dev)\//
          m
        elsif url =~ /^\//
          m.sub(/="/, "=\"#{preview_url}")
        else
          m
        end
      end

      h  = []
      h << view_context.stylesheet_link_tag("cms/preview")
      h << view_context.javascript_include_tag("cms/preview")
      h << '<link href="/assets/css/datetimepicker/jquery.datetimepicker.css" rel="stylesheet" />'
      h << '<script src="/assets/js/jquery.datetimepicker.js"></script>'
      h << '<div id="ss-preview">'
      h << '<input type="text" class="date" value="' + @cur_date.strftime("%Y/%m/%d %H:%M") + '" />'
      h << '<input type="button" class="preview" value="Preview">'
      h << '</div>'

      body.sub!("</body>", h.join("\n") + "</body>")

      response.body = body
    end
end
