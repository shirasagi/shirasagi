module Cms::PublicFilter::Layout
  extend ActiveSupport::Concern
  include Cms::PublicFilter::Agent
  include Cms::PublicHelper
  include Cms::PublicFilter::OpenGraph
  include Cms::PublicFilter::TwitterCard

  included do
    helper_method :render_layout_parts
  end

  private

  def filters
    @filters ||= begin
      request.env["ss.filters"] ||= []
    end
  end

  def find_part(path)
    part = Cms::Part.site(@cur_site).filename(path).first
    return unless part
    @preview || part.public? ? part.becomes_with_route : nil
  end

  def render_part(part, opts = {})
    return part.html if part.route == "cms/free"

    path = "/.s#{@cur_site.id}/parts/#{part.route}"
    spec = recognize_agent path, method: "GET"
    return unless spec

    @cur_part = part
    controller = part.route.sub(/\/.*/, "/agents/#{spec[:cell]}")

    agent = new_agent controller
    agent.controller.params.merge! spec
    agent.controller.request = ActionDispatch::Request.new(request.env.merge("REQUEST_METHOD" => "GET"))
    resp = agent.render spec[:action]
    body = resp.body

    if body =~ /\#\{.*?parent_name\}/
      parent = Cms::Node.site(@cur_site).filename(@cur_main_path.to_s.sub(/^\//, "").sub(/\/[\w\-\.]*?$/, "")).first
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
      m = m.sub(/ class="/, %( class="#{body_class(@cur_main_path)} )     ) if m =~ / class="/
      m = m.sub(/<body/,    %(<body class="#{body_class(@cur_main_path)}")) unless m =~ / class="/
      m = m.sub(/<body/,    %(<body id="#{body_id(@cur_main_path)}")      ) unless m =~ / id="/
      m
    end

    body = body.sub(/<title>.*?<\/title>(\r|\n)*/) do |m|
      @window_name = m.gsub(/<title>|<\/title>(\r|\n)*/, '')
      ''
    end

    body = body.sub(/<meta[^>]*charset=[^>]*\/>/) do |m|
      ''
    end

    html = render_layout_parts(body)

    if notice
      notice_html   = %(<div id="ss-notice"><div class="wrap">#{notice}</div></div>)
      response.body = %(#{notice_html}#{response.body})
    end

    html = render_template_variables(html)
    html.sub!(/(\{\{ yield \}\}|<\/ yield \/>)/) { response.body }
    html
  end

  def render_template_variables(html)
    html.gsub!('#{page_name}') do
      ERB::Util.html_escape(@cur_item.name)
    end

    html.gsub!('#{parent_name}') do
      ERB::Util.html_escape(@cur_item.parent ? @cur_item.parent.name : "")
    end

    date = nil
    html.gsub!(/#\{page_released(|\.default|\.iso|\.long|\.short)\}/) do
      date ||= ERB::Util.html_escape(@cur_item.released)
      case $1
      when '.default' then date_convert(date, :default)
      when '.iso' then date_convert(date, :iso)
      when '.long' then date_convert(date, :long)
      when '.short' then date_convert(date, :short)
      else date_convert(date)
      end
    end

    date = nil
    html.gsub!(/#\{page_updated(|\.default|\.iso|\.long|\.short)\}/) do
      date ||= ERB::Util.html_escape(@cur_item.updated)
      case $1
      when '.default' then date_convert(date, :default)
      when '.iso' then date_convert(date, :iso)
      when '.long' then date_convert(date, :long)
      when '.short' then date_convert(date, :short)
      else date_convert(date)
      end
    end

    html
  end

  def render_layout_parts(html)
    return html if html.blank?

    # TODO: deprecated </ />
    parts = {}
    html = html.gsub(/(<\/|\{\{) part "(.*?)" (\/>|\}\})/) do
      path = "#{$2}.part.html"
      path = path[0] == "/" ? path.sub(/^\//, "") : @cur_layout.dirname(path)
      parts[path] = nil
      "{{ part \"#{path}\" }}"
    end

    criteria = Cms::Part.site(@cur_site).and_public.any_in(filename: parts.keys)
    criteria = criteria.where(mobile_view: "show") if filters.include?(:mobile)
    criteria.each { |part| parts[part.filename] = part }

    return html.gsub(/\{\{ part "(.*?)" \}\}/) do
      path = $1
      part = parts[path]
      part ? render_layout_part(part) : ''
    end
  end

  def render_layout_part(part)
    if part.ajax_view == "enabled" && !filters.include?(:mobile) && !@preview
      part.ajax_html
    else
      render_part(part.becomes_with_route)
    end
  end

  def date_convert(date, format = nil)
    return "" unless date

    if format.nil?
      I18n.l date.to_date
    else
      I18n.l date.to_date, format: format.to_sym
    end
  rescue
    ""
  end

  public

  def mobile_path?
    filters.include?(:mobile)
  end

  def preview_path?
    filters.include?(:preview)
  end

  def stylesheets
    @stylesheets || []
  end

  def stylesheet(path)
    @stylesheets ||= []
    @stylesheets << path unless @stylesheets.include?(path)
  end

  def javascripts
    @javascripts || []
  end

  def javascript(path)
    @javascripts ||= []
    @javascripts << path unless @javascripts.include?(path)
  end

  def javascript_configs
    if @javascript_config.nil?
      @javascript_config = {}

      conf = Cms::ThemeTemplate.to_config(site: @cur_site, preview_path: preview_path?)
      @javascript_config.merge!(conf)

      conf = Recommend::History::Log.to_config(
        site: @cur_site, item: (@cur_page || @cur_node || @cur_part), path: @cur_path,
        preview_path: preview_path?
      )
      @javascript_config.merge!(conf)
    end
    @javascript_config
  end

  def javascript_config(conf)
    javascript_configs
    @javascript_config.merge!(conf)
  end
end
