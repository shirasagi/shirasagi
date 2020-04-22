module Translate::PublicFilter
  extend ActiveSupport::Concern

  included do
    after_action :render_translate, if: ->{ filters.include?(:translate) }
  end

  private

  def set_request_path_with_translate
    return if !@cur_site.translate_enabled?
    return if @cur_main_path !~ /^#{@cur_site.translate_location}\/.+?\//

    if browser.bot?
      Rails.logger.warn("translate denied : #{request.user_agent}")
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

    convertor = Translate::Convertor.new(@cur_site, @translate_source, @translate_target)
    body = convertor.convert(body)

    if @cur_site.request_word_limit_exceeded && body =~ /<body data-translate=\".+?\"/
      h = []
      h << '<script src="/assets/js/jquery.colorbox.js"></script>'
      h << '<link rel="stylesheet" media="screen" href="/assets/css/colorbox/colorbox.css">'
      h << '<div id="ss-translate-error">'
      h << ApplicationController.helpers.sanitize(@cur_site.translate_api_limit_exceeded_html)
      h << '</div>'
      h << '<script>$.colorbox({open: true, html: $("#ss-translate-error")});</script>'
      h << '</html>'
      body.sub!('</html>', h.join)
    end

    if params[:format] == "json"
      body = ActiveSupport::JSON.encode(body)
    end

    response.body = body
  end
end
