module ApplicationHelper
  include Category::CategoryHelper
  include SS::AutoLink

  def tryb(&block)
    begin
      yield
    rescue
      nil
    end
  end

  def br(*args)
    options = args.extract_options!
    option_html_escape = options.fetch(:html_escape, true)

    array = args
    array.flatten!
    # stringify
    array.map! { |value| value.to_s }
    # html escape
    array.map! { |value| h(value) } if option_html_escape
    # replace new-line with "<br />"
    array.map! { |value| value.gsub(/\R/, "<br />") }

    array.join("<br />").html_safe
  end

  #def br_not_h(str)
  #  br(str, html_escape: false)
  #end

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
    current = current.sub(@cur_site.mobile_location, '') if @cur_site.mobile_enabled?
    current = current.sub(SS.config.kana.location, '') if !SS.config.kana.disable
    current = current.sub(/#{::Regexp.escape(SS.config.translate.location)}\/[^\/]*/, '') if @cur_site.translate_enabled?
    return nil if current.delete("/").blank?
    return :current if url.sub(/\/index\.html$/, "/") == current.sub(/\/index\.html$/, "/")
    return :current if current.match?(/^#{::Regexp.escape(url)}(\/|\?|$)/)
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
    h << %(<ul class="tooltip-content">)
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

  def content_tag_if(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    # content_tag(*args, &block)
    if block_given?
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
    end

    if_condition = options ? options.delete(:if) : nil
    if if_condition.respond_to?(:call)
      if_condition = if_condition.call
    end

    if if_condition
      return content_tag(name, content_or_options_with_block, options, escape, &block)
    end

    if block_given?
      return capture { yield }
    end

    content_or_options_with_block
  end

  def liquid_registers
    registers = {
      cur_site: @cur_site,
      preview: @preview,
      cur_path: @cur_path,
      cur_main_path: @cur_main_path,
      mobile: false
    }

    registers[:mobile] = controller.filters.include?(:mobile) if controller.respond_to?(:filters)
    registers[:cur_part] = @cur_part if @cur_part
    registers[:cur_node] = @cur_node if @cur_node
    registers[:cur_page] = @cur_page if @cur_page
    registers[:cur_date] = @cur_date if @cur_date

    registers
  end

  def loading(options = {})
    options = options.dup
    options[:style] ||= "vertical-align:middle"
    options[:alt] ||= "loading.."
    options[:border] ||= 0
    options[:widtth] ||= 16
    options[:height] ||= 11
    options[:class] ||= %w(ss-base-loading)

    # '<img style="vertical-align:middle" src="/assets/img/loading.gif" alt="loading.." border="0" widtth="16" height="11" />'
    image_tag("/assets/img/loading.gif", options)
  end

  def status_code_to_symbol(status_code)
    return status_code if !status_code.numeric?

    message = ::Rack::Utils::HTTP_STATUS_CODES[status_code.to_i]
    return status_code if message.blank?

    message.downcase.gsub(/\s|-|'/, '_').to_sym
  end

  def show_image_info(file)
    return nil unless file

    content_tag(:div, class: "file-view", data: { "file-id" => file.id }) do
      link_to(file.url, target: "_blank") do
        output_buffer << content_tag(:div, class: "thumb") do
          if file.image?
            image_tag(file.thumb_url, alt: file.basename)
          else
            content_tag(:span, file.extname, class: [ "ext", "icon-#{file.extname}" ])
          end
        end
        output_buffer << content_tag(:div, file.humanized_name, class: "name")
      end
    end
  end

  def render_application_logo(site = nil)
    site ||= @cur_site
    return SS.config.ss.application_logo_html.html_safe if site.blank?

    name = site.logo_application_name
    image = site.logo_application_image
    return SS.config.ss.application_logo_html.html_safe if name.blank? && image.blank?

    content_tag(:div, class: "ss-logo-wrap") do
      if image.present?
        output_buffer << image_tag(image.url, alt: name || SS.config.ss.application_name)
      end
      if name.present?
        output_buffer << content_tag(:span, name, class: "ss-logo-application-name")
      end
    end
  end

  def required_label
    %(<div class="required">&lt;#{I18n.t('ss.required')}&gt;</div>).html_safe
  end
end
