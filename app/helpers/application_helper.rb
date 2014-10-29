module ApplicationHelper
  def tryb(&block)
    begin
      block.call
    rescue NoMethodError
      nil
    end
  end

  def t(key, opts = {})
    opts[:scope] = [:views] if key !~ /\./ && !opts[:scope]
    I18n.t key, opts.merge(default: key.to_s.humanize)
  end

  def br(str)
    h(str.to_s).gsub(/(\r\n?)|(\n)/, "<br />").html_safe
  end

  def snip(str, opt = {})
    len = opt[:length] || 80
    "#{str.to_s[0..len-1]}#{str.to_s.size > len ? ".." : ""}".html_safe
  end

  def current_url?(url)
    current = @cur_path.sub(/\?.*/, "")
    return nil if current.gsub("/", "").blank?
    return :current if url.sub(/\/index\.html$/, "/") == current.sub(/\/index\.html$/, "/")
    return :current if current =~ /^#{Regexp.escape(url)}(\/|\?|$)/
    nil
  end

  def link_to(*args)
    if args[0].class == Symbol
      args[0] = I18n.t "views.links.#{args[0]}", default: nil || t(args[0])
    end
    super *args
  end

  def jquery(&block)
    javascript_tag do
      "$(function() {\n#{capture(&block)}\n});".html_safe
    end
  end

  def coffee(&block)
    javascript_tag do
      CoffeeScript.compile(capture(&block)).html_safe
    end
  end

  def scss(&block)
    opts = Rails.application.config.sass
    sass = Sass::Engine.new "@import 'compass/css3';\n" + capture(&block),
      syntax: :scss,
      cache: false,
      style: :compressed,
      debug_info: false,
      load_paths: opts.load_paths[1..-1] + ["#{Gem.loaded_specs['compass'].full_gem_path}/frameworks/compass/stylesheets"]

    h  = []
    h << "<style>"
    h << sass.render
    h << "</style>"
    h.join("\n").html_safe
  end

  def tt(key, html_wrap = true)
    msg = I18n.t("tooltip.#{key}", default: "")
    return msg if msg.blank? || !html_wrap
    msg = [msg] if msg.class.to_s == "String"
    list = msg.map {|d| "<li>" + d.gsub(/\r\n|\n/, "<br />") + "</li>"}

    h  = []
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

  def mail_to_entity(email_address, name = nil, html_options = {})
    return "" if email_address.blank?
    email_address = email_address.gsub(/@/, "&#64;").gsub(/\./, "&#46;").html_safe
    name = email_address if name.blank?
    mail_to(email_address, name, html_options).html_safe
  end

end
