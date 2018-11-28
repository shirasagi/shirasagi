module ApplicationHelper
  include Category::CategoryHelper

  def tryb(&block)
    begin
      yield
    rescue
      nil
    end
  end

  def br(str)
    h(str.to_s).gsub(/(\r\n?)|(\n)/, "<br />").html_safe
  end

  def paragraph(str)
    texts = h(str.to_s).split(/(\r\n?)|(\n)/)
    texts.map! { |t| t.strip }
    texts.select!(&:present?)
    texts.reduce('') { |a, e| a + "<p>#{e}</p>" }.html_safe
  end

  def snip(str, opt = {})
    len = opt[:length] || 80
    "#{str.to_s[0..len-1]}#{str.to_s.size > len ? ".." : ""}".html_safe
  end

  def sanitize_with(html, options = {})
    options[:tags] += ActionView::Base.sanitized_allowed_tags.to_a if options[:tags]
    options[:attributes] += ActionView::Base.sanitized_allowed_attributes.to_a if options[:attributes]
    ApplicationController.helpers.sanitize(html, options)
  end

  def current_url?(url)
    current = @cur_path.sub(/\?.*/, "")
    return nil if current.delete("/").blank?
    return :current if url.sub(/\/index\.html$/, "/") == current.sub(/\/index\.html$/, "/")
    return :current if current =~ /^#{::Regexp.escape(url)}(\/|\?|$)/
    nil
  end

  def url_for(*args)
    url = super
    if SS::MobileSupport.mobile?(request)
      url = SS::MobileSupport.embed_mobile_path(request, url)
    end
    url
  end

  def jquery(&block)
    javascript_tag do
      "$(function() {\n#{capture(&block)}\n});".html_safe
    end
  end

  # @deprecated
  def coffee(&block)
    javascript_tag do
      CoffeeScript.compile(capture(&block)).html_safe
    end
  end

  # @deprecated
  def scss(&block)
    opts = Rails.application.config.sass
    load_paths = opts.load_paths[1..-1] || []
    load_paths << "#{Rails.root}/vendor/assets/stylesheets"

    sass = Sass::Engine.new(
      "@import 'compass-mixins/lib/compass';\n" + capture(&block),
      cache: false,
      debug_info: false,
      inline_source_maps: false,
      load_paths: load_paths,
      style: :compressed,
      syntax: :scss
    )

    h = []
    h << "<style>"
    h << sass.render
    h << "</style>"
    h.join("\n").html_safe
  end

  def tt(key, *args)
    opts = args.extract_options!

    html_wrap = args.shift
    html_wrap = opts[:html_wrap] if html_wrap.nil?
    html_wrap = true if html_wrap.nil?

    msg = nil
    Array(opts[:scope]).flatten.each do |scope|
      msg = I18n.t(key, default: '', scope: scope)
      break if msg.present?
    end
    msg = I18n.t(key, default: '', scope: 'tooltip') if msg.blank?
    return msg if msg.blank? || !html_wrap
    msg = [msg] if msg.class.to_s == "String"
    list = msg.map { |d| "<li>" + d.gsub(/\r\n|\n/, "<br />") + "</li>" }

    h = []
    h << %(<div class="tooltip">?)
    h << %(<ul>)
    h << list
    h << %(</ul>)
    h << %(</div>)
    h.join("\n").html_safe
  end

  def render_agent(controller_name, action)
    controller.render_agent(controller_name, action).body.html_safe
  end

  def mail_to_entity(email_address, name = nil, html_options = {}, &block)
    if block_given?
      html_options = name
      name = nil
    end
    html_options = (html_options || {}).stringify_keys

    extras = %w(cc bcc body subject).map! do |item|
      option = html_options.delete(item) || next
      "#{item}=#{Rack::Utils.escape_path(option)}"
    end.compact
    extras = extras.empty? ? '' : '?' + extras.join('&')

    email_address = email_address.gsub(/@/, "&#64;").gsub(/\./, "&#46;").html_safe if email_address.present?
    html_options["href"] = "mailto:#{email_address}#{extras}".html_safe

    content_tag(:a, name || email_address, html_options, &block)
  end

  def dropdown_link(name = nil, url_options = nil, options = nil, html_options = nil, &block)
    options ||= {}
    html_options ||= {}

    inner = capture(&block) if block_given?
    if inner.blank?
      return link_to(name, url_options, html_options)
    end

    html_options[:class] = [ html_options[:class].presence ].flatten.compact

    split = options.delete(:split)
    if split
      html_options[:class] << 'no-margin'
    else
      html_options[:class] << 'dropdown-toggle'
    end
    content_tag(:div, class: 'dropdown') do
      output_buffer << link_to(name, split ? url_options : '#', html_options)
      if split
        output_buffer << tag(:span, class: %w(dropdown-toggle dropdown-toggle-split))
      end
      output_buffer << content_tag(:div, class: %w(dropdown-menu gws-dropdown-menu cms-dropdown-menu)) do
        inner
      end
    end
  end
end
