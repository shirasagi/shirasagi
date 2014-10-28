module Cms::PublicFilter::Layout
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Agent

  private
    def find_part(path)
      part = Cms::Part.site(@cur_site).filename(path).first
      return unless part
      @preview || part.public?  ? part.becomes_with_route : nil
    end

    def render_part(part, opts = {})
      return part.html if part.route == "cms/frees"
      return part.ajax_html if part.ajax_view == "enabled" && !opts[:xhr]

      path = "/.#{@cur_site.host}/parts/#{part.route}"
      spec = recognize_agent path, method: "GET"
      return unless spec

      @cur_part = part
      controller = part.route.sub(/\/.*/, "/agents/#{spec[:cell]}/view")

      agent = new_agent controller
      agent.controller.params.merge! spec
      resp = agent.render spec[:action]

      @cur_part = nil
      resp.body
    end

    def render_layout(layout)
      @cur_layout = layout
      @cur_item   = @cur_page || @cur_node

      @window_name = @cur_site.name
      @window_name = "#{@cur_item.name} - #{@cur_site.name}" if @cur_item.filename != "index.html"

      @cur_layout.keywords    = @cur_item.keywords if @cur_item.respond_to?(:keywords)
      @cur_layout.description = @cur_item.description if @cur_item.respond_to?(:description)

      html = @cur_layout.body.to_s.gsub(/<\/ part ".+?" \/>/) do |m|
        path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : @cur_layout.dirname(path)
        render_layout_part(path)
      end

      html.gsub!('#{page_name}', @cur_item.name)
      html.sub!("</ yield />", response.body)
      html
    end

    def render_layout_part(path)
      part = Cms::Part.site(@cur_site)
      part = part.where(mobile_view: "show") if @filter == :mobile
      part = part.filename(path).first
      return unless part

      if part.ajax_view == "enabled"
        render_part(part.becomes_with_route, xhr: true)
      else
        render_part(part.becomes_with_route)
      end
    end
end
