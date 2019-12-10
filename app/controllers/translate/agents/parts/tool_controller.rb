class Translate::Agents::Parts::ToolController < ApplicationController
  include Cms::PartFilter::View

  def http_accept_language
    @http_accept_language ||= begin
      request.env["http_accept_language.parser"] || HttpAcceptLanguage::Parser.new(request.env["HTTP_ACCEPT_LANGUAGE"])
    end
  end

  def index
    available = SS.config.translate.lang_codes.keys
    @preferred_lang = http_accept_language.preferred_language_from(available)
  end
end
