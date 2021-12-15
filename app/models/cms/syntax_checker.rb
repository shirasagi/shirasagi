module Cms::SyntaxChecker
  CheckerContext = Struct.new(:cur_site, :cur_user, :contents, :errors)
  CorrectorContext = Struct.new(:cur_site, :cur_user, :content, :params, :result)

  module_function

  mattr_accessor :html_checkers, :text_checkers
  self.html_checkers = [
    # checkers for both html and text
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker,
    # checkers only for html
    Cms::SyntaxChecker::AdjacentAChecker,
    Cms::SyntaxChecker::AppletAltChecker,
    Cms::SyntaxChecker::AreaAltChecker,
    Cms::SyntaxChecker::EmbeddedMediaChecker,
    Cms::SyntaxChecker::ImgAltChecker,
    Cms::SyntaxChecker::ImgDataUriSchemeChecker,
    Cms::SyntaxChecker::LinkTextChecker,
    Cms::SyntaxChecker::ObjectTextChecker,
    Cms::SyntaxChecker::OrderOfHChecker,
    Cms::SyntaxChecker::TableChecker
  ]
  self.text_checkers = [
    # checkers for both html and text
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker
  ]

  def check(cur_site:, cur_user:, contents:)
    context = Cms::SyntaxChecker::CheckerContext.new(cur_site, cur_user, contents, [])

    contents.each do |id, content|
      if content["resolve"] == "html"
        checkers = Cms::SyntaxChecker.html_checkers
      else
        checkers = Cms::SyntaxChecker.text_checkers
      end

      Cms::SyntaxChecker::Base.each_html_with_index(content) do |html, idx|
        fragment = Nokogiri::HTML5.fragment(html)
        checkers.each do |checker|
          innstance = checker.new
          innstance.check(context, id, idx, html, fragment)
        rescue => e
          Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
        end
      end
    end

    context
  end

  def correct(cur_site:, cur_user:, content:, collector:, params:)
    default_result = content["content"]
    context = Cms::SyntaxChecker::CorrectorContext.new(cur_site, cur_user, content, params, default_result)

    if content["resolve"] == "html"
      checkers = Cms::SyntaxChecker.html_checkers
    else
      checkers = Cms::SyntaxChecker.text_checkers
    end

    checker = checkers.find { |checker| checker.name == collector }
    return context if !checker

    innstance = checker.new
    innstance.correct(context)

    context
  end
end
