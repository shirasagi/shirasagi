module Translate::PublicFilter
  extend ActiveSupport::Concern

  included do
    after_action :render_translate, if: ->{ filters.include?(:translate) }
  end

  private

  def set_request_path_with_translate
    return if !@cur_site.translate_enabled?
    return if @cur_main_path !~ /^#{@cur_site.translate_location}\/.+?\//

    deny_message = nil
    if browser.bot?
      deny_message = "bot access: #{request.user_agent}"
    end
    if @cur_site.translate_deny_no_refererr? && request.referer.blank?
      deny_message = "no referer access"
    end
    Translate::AccessLog.create_log!(@cur_site, request) do |item|
      item.path = request_path
      item.remote_addr = remote_addr
      item.deny_message = deny_message
    end

    if deny_message.present?
      Rails.logger.info("translate denied due to a #{deny_message}")
      return
    end

    main_path = @cur_main_path.sub(/^#{@cur_site.translate_location}\/(.+?)\//, "/")

    @translate_target = @cur_site.find_translate_target(::Regexp.last_match[1])
    @translate_source = @cur_site.translate_source

    if @translate_target
      filters << :translate
      request.env["ss.translate_target"] = @translate_target.code
      @cur_main_path = main_path
    end
  end

  def render_translate
    body = response.body

    if params[:format] == "json"
      body = ActiveSupport::JSON.decode(body)
    end

    converter = Translate::Converter.new(@cur_site, @translate_source, @translate_target)
    body = converter.convert(body)

    limit_exceeded = @cur_site.request_word_limit_exceeded
    exceeded_html = @cur_site.translate_api_limit_exceeded_html
    if limit_exceeded && exceeded_html.present? && body =~ /<body data-translate=".+?"/
      h = <<~HTML
        #{ApplicationController.helpers.stylesheet_link_tag("colorbox", media: "all")}
        #{ApplicationController.helpers.javascript_include_tag("colorbox", defer: true)}
        <div id="ss-translate-error">
          #{ApplicationController.helpers.sanitize(@cur_site.translate_api_limit_exceeded_html)}
        </div>
        <script>
          SS.ready(function() {
            $.colorbox({open: true, html: $("#ss-translate-error")});
          });
        </script>
      HTML
      body.sub!('</html>', h + '</html>')
    end

    if params[:format] == "json"
      body = ActiveSupport::JSON.encode(body)
    end

    response.body = body
  end
end
