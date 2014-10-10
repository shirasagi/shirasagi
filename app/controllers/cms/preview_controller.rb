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
      @cur_path.sub!(/^#{cms_preview_path}/, "")
      @cur_path = "index.html" if @cur_path.blank?
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
      body = response.body

      body.gsub!(/(href|src)=".*?"/) do |m|
        url = m.match(/.*?="(.*?)"/)[1]
        if url =~ /^\/(assets|assets-dev)\//
          m
        elsif url =~ /^\//
          m.sub(/="/, "=\"#{cms_preview_path}")
        else
          m
        end
      end

      css  = "position: fixed; top: 0px; left: 0px; padding: 5px;"
      css << "background-color: rgba(0, 150, 100, 0.6); color: #fff; font-weight: bold;"
      mark = %(<div id="ss-preview" style="#{css}">Preview</div>)
      body.sub!("</body>", "#{mark}</body>")

      response.body = body
    end
end
