module Cms::PublicFilter::Layout
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Agent
  include Cms::PublicHelper

  private
    def filters
      @filters ||= []
      @filters
    end

    def find_part(path)
      part = Cms::Part.site(@cur_site).filename(path).first
      return unless part
      @preview || part.public?  ? part.becomes_with_route : nil
    end

    def render_part(part, opts = {})
      return part.html if part.route == "cms/frees"

      path = "/.#{@cur_site.host}/parts/#{part.route}"
      spec = recognize_agent path, method: "GET"
      return unless spec

      @cur_part = part
      controller = part.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

      agent = new_agent controller
      agent.controller.params.merge! spec
      resp = agent.render spec[:action]
      body = resp.body

      if body =~ /\#\{.*?parent_name\}/
        parent = Cms::Node.filename(@cur_path.to_s.sub(/^\//, "").sub(/\/[\w\-\.]*?$/, "")).first
        if parent
          body.gsub!('#{parent_name}', ERB::Util.html_escape(parent.name))
          body.gsub!('#{parent.parent_name}', ERB::Util.html_escape(parent.parent ? parent.parent.name : parent.name))
        end
      end

      @cur_part = nil
      body
    end

    def render_layout(layout)
      @cur_layout = layout
      @cur_item   = @cur_page || @cur_node

      @window_name = @cur_site.name
      @window_name = "#{@cur_item.name} - #{@cur_site.name}" if @cur_item.filename != "index.html"

      @cur_layout.keywords    = @cur_item.keywords if @cur_item.respond_to?(:keywords)
      @cur_layout.description = @cur_item.description if @cur_item.respond_to?(:description)

      body = @cur_layout.body.to_s
      body = body.sub(/<body.*?>/) do |m|
        m = m.sub(/ class="/, %( class="#{body_class(@cur_path)} )     ) if m =~ / class="/
        m = m.sub(/<body/,    %(<body class="#{body_class(@cur_path)}")) unless m =~ / class="/
        m = m.sub(/<body/,    %(<body id="#{body_id(@cur_path)}")      ) unless m =~ / id="/
        m
      end

      html = body.gsub(/<\/ part ".+?" \/>/) do |m|
        path = m.sub(/<\/ part "(.+)?" \/>/, '\\1') + ".part.html"
        path = path[0] == "/" ? path.sub(/^\//, "") : @cur_layout.dirname(path)
        render_layout_part(path)
      end

      if notice
        notice_html   = %(<div id="ss-notice"><div class="wrap">#{notice}</div></div>)
        response.body = %(#{notice_html}#{response.body})
      end

      html.gsub!('#{page_name}', ERB::Util.html_escape(@cur_item.name))
      html.gsub!('#{parent_name}', ERB::Util.html_escape(@cur_item.parent ? @cur_item.parent.name : ""))
      html.sub!("</ yield />", response.body)
      html
    end

    def render_layout_part(path)
      part = Cms::Part.site(@cur_site).public
      part = part.where(mobile_view: "show") if filters.include?(:mobile)
      part = part.filename(path).first
      return unless part

      if part.ajax_view == "enabled" && !filters.include?(:mobile)
        part.ajax_html
      else
        render_part(part.becomes_with_route)
      end
    end
end
