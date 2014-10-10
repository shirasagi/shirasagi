module Cms::ReleaseFilter::Layout
  extend ActiveSupport::Concern
  include Cms::ReleaseFilter

  private
    def find_part(path)
      part = Cms::Part.site(@cur_site).filename(path).first
      return unless part

      @preview || part.public?  ? part : nil
    end

    def render_part(part, opts = {})
      return part.html if part.route == "cms/frees"
      return part.ajax_html if part.ajax_view == "enabled" && !opts[:xhr]

      path = "/.#{@cur_site.host}/parts/#{part.route}"
      cell = recognize_path path, method: "GET"
      return unless cell

      @cur_part = part
      resp = render_cell part.route.sub(/\/.*/, "/#{cell[:controller]}/view"), cell[:action]
      @cur_part = nil
      resp
    end

    def render_layout(body, opts = {})
      @cur_item = @cur_page || @cur_node

      @window_name = @cur_site.name
      @window_name = "#{@cur_item.name} - #{@cur_site.name}" if @cur_item.filename != "index.html"
      @cur_layout.keywords = @cur_item.keywords if @cur_item.respond_to?(:keywords)
      @cur_layout.description = @cur_item.description if @cur_item.respond_to?(:description)

      html = @cur_layout.body.to_s.gsub(/<\/ part ".+?" \/>/) do |m|
        path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : @cur_layout.dirname(path)

        part = Cms::Part.site(@cur_site)
        part = part.where mobile_view: "show" if @filter == :mobile
        part = part.filename(path).first
        part = part.becomes_with_route if part
        part ? render_part(part) : ""
      end

      html.gsub!('#{page_name}', @cur_item.name)

      html.sub("</ yield />", body)
    end
end
