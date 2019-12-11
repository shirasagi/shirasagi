class Translate::Agents::Parts::ToolController < ApplicationController
  include Cms::PartFilter::View

  def http_accept_language
    @http_accept_language ||= begin
      request.env["http_accept_language.parser"] || HttpAcceptLanguage::Parser.new(request.env["HTTP_ACCEPT_LANGUAGE"])
    end
  end

  def index
    if !@cur_site.translate_enabled?
      return
    end

    @lang_codes = @cur_site.available_lang_codes
    @preferred_lang = http_accept_language.preferred_language_from(@lang_codes.keys)

    if @preferred_lang != @cur_site.translate_source
      Rails.logger.info "Accept-Language : #{http_accept_language.user_preferred_languages.join(" ")}"
    end
  end
end
