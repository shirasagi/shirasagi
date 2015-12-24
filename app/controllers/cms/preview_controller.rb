class Cms::PreviewController < ApplicationController
  include Cms::BaseFilter
  include Cms::PublicFilter
  include Mobile::PublicFilter
  include Kana::PublicFilter
  include Fs::FileFilter

  before_action :set_group
  before_action :set_path_with_preview, prepend: true
  after_action :render_form_preview, only: :form_preview
  after_action :render_preview, if: ->{ @file =~ /\.html$/ }
  after_action :render_mobile, if: ->{ mobile_path? }

  if SS.config.cms.remote_preview
    skip_filter :logged_in?
    skip_filter :set_group
  end

  public
    def form_preview
      preview_item = params.require(:preview_item).permit!
      path = params[:path]
      id = preview_item.delete("id")
      route = preview_item.delete("route")

      page = Cms::Page.find(id) rescue Cms::Page.new(route: route)
      page = page.becomes_with_route
      page.attributes = preview_item
      page.site = @cur_site
      page.lock_owner_id = nil if page.respond_to?(:lock_owner_id)
      page.lock_until = nil if page.respond_to?(:lock_until)

      raise page_not_found unless page.name.present?
      raise page_not_found unless page.basename.present?
      page.basename = page.basename.sub(/\..+?$/, "") + ".html"

      @cur_layout = Cms::Layout.where(id: page.layout_id).first
      @cur_body_layout = Cms::BodyLayout.where(id: page.body_layout_id).first
      page.layout_id = nil if @cur_layout.nil?
      page.body_layout_id = nil if @cur_body_layout.nil?
      @cur_node = Cms::Node.where(filename: /^#{path.sub(/\/$/, "")}/).first
      @cur_page = page
      @preview_page = page

      resp = render_page(page, method: "GET")
      return page_not_found unless resp
      self.response = resp

      if page.layout
        render inline: render_layout(page.layout), layout: "cms/page"
      else
        @_response_body = response.body
      end
    rescue
      render_error 400
    end

  private
    def set_site
      @cur_site = SS::Site.find params[:site]
      @preview  = true
    end

    def set_path_with_preview
      @cur_path ||= request.env["REQUEST_PATH"] || request.path
      @cur_path.sub!(/^#{cms_preview_path}(\d+)?/, "")
      @cur_path = "index.html" if @cur_path.blank?
      @cur_path = URI.decode(@cur_path)
      @cur_date = params[:preview_date].present? ? params[:preview_date].in_time_zone : Time.zone.now
    end

    def x_sendfile(file = @file)
      return if file =~ /\.(ht|x)ml$/
      return if file =~ /\.part\.json$/
      super
      return if response.body.present?

      if @cur_path =~ /^\/fs\//
        path = @cur_path.sub("/thumb/", "/")
        filename = ::File.basename(path)
        id = ::File.dirname(path).sub("/fs/", "").sub("/_", "").delete("/")
        @item = SS::File.find_by id: id, filename: filename

        if @cur_path =~ /\/thumb\//
          if @item.thumb
            @item = @item.thumb
          else
            @thumb_width  = params[:width]
            @thumb_height = params[:height]
          end
        end

        if @thumb_width && @thumb_height
          send_thumb @item.read, type: @item.content_type, filename: @item.filename,
            disposition: :inline, width: @thumb_width, height: @thumb_height
          return
        else
          send_file @item.path, type: @item.content_type, filename: @item.filename,
            disposition: :inline, x_sendfile: true
          return
        end
      end
      #raise "404" unless Fs.exists?(file)
    end

    def render_preview
      preview_url = cms_preview_path preview_date: params[:preview_date]

      body = response.body
      body.gsub!(/(href|src)=".*?"/) do |m|
        url = m.match(/.*?="(.*?)"/)[1]
        if url =~ /^\/(assets|assets-dev)\//
          m
        elsif url =~ /^\/(?!\/)/
          m.sub(/="/, "=\"#{preview_url}")
        else
          m
        end
      end

      h = []
      h << view_context.stylesheet_link_tag("cms/preview")
      h << view_context.javascript_include_tag("cms/public") if mobile_path?
      h << view_context.javascript_include_tag("cms/preview")
      h << '<link href="/assets/css/colorbox/colorbox.css" rel="stylesheet" />'
      h << '<script src="/assets/js/jquery.colorbox.js"></script>'
      unless @preview_page
        h << '<script>'
        h << '$(function(){'
        h << '  SS_Preview.mobile_path = "' + SS.config.mobile.location + '";'
        h << '  SS_Preview.render();'
        h << '});'
        h << '</script>'
        h << '<div id="ss-preview">'
        h << '<input type="text" class="date" value="' + @cur_date.strftime("%Y/%m/%d %H:%M") + '" />'
        h << '<input type="button" class="preview" value="' + t("views.links.pc") + '">'
        h << '<input type="button" class="mobile" value=' + t("views.links.mobile") + '>'
        h << '</div>'
      end

      body.sub!("</body>", h.join("\n") + "</body>")

      response.body = body
    end

    def render_form_preview
      require "uri"

      body = response.body
      body.gsub!(/(href|src)=".*?"/) do |m|
        url = m.match(/.*?="(.*?)"/)[1]
        scheme = ::URI.parse(url).scheme rescue true

        if scheme
          m
        elsif url =~ /^\/\//
          m
        else
          full_url = @cur_node ? @cur_node.full_url : @cur_site.full_url
          m.sub(url, ::URI.join(full_url, url).to_s)
        end
      end

      response.body = body
    end
end
