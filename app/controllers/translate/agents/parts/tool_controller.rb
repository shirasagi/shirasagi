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

    @available_lang = {}

    items = [@cur_site.translate_source] + @cur_site.translate_targets
    items.each do |item|
      item.accept_languages.each do |lang|
        @available_lang[lang] ||= item
      end
    end

    @preferred_lang = http_accept_language.preferred_language_from(@available_lang.keys)
    @preferred_lang = @available_lang[@preferred_lang]
  end
end
