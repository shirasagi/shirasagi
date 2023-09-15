module Cms::SyntaxChecker
  extend SS::RescueWith

  FULL_WIDTH_SPACE = '　'.freeze
  SP = " ".freeze
  HALF_AL_NUM_PAT = "A-Za-z0-9".freeze
  FULL_AL_NUM_PAT = "Ａ-Ｚａ-ｚ０-９".freeze
  AL_NUM_PAT = "#{HALF_AL_NUM_PAT}#{FULL_AL_NUM_PAT}".freeze
  AL_NUM_SP_PAT = "#{AL_NUM_PAT}#{SP}".freeze
  AL_NUM_REGEX = /[#{AL_NUM_PAT}]([#{AL_NUM_SP_PAT}]*[#{AL_NUM_PAT}])?/.freeze

  CheckerContext = Struct.new(:cur_site, :cur_user, :contents, :errors, :header_check, :h_level_check) #checkを追加
  CorrectorContext = Struct.new(:cur_site, :cur_user, :content, :params, :result) do
    def set_result(ret)
      if content["type"] == "array"
        self.result = ret
      else
        self.result = ret[0]
      end
    end
  end

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
    Cms::SyntaxChecker::AreaAltChecker,
    Cms::SyntaxChecker::EmbeddedMediaChecker,
    Cms::SyntaxChecker::ImgAltChecker,
    Cms::SyntaxChecker::ImgDataUriSchemeChecker,
    Cms::SyntaxChecker::LinkTextChecker,
    Cms::SyntaxChecker::OrderOfHChecker,
    Cms::SyntaxChecker::TableChecker,
    Cms::SyntaxChecker::UrlSchemeChecker,
    Cms::SyntaxChecker::InternalLinkChecker
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
    context = Cms::SyntaxChecker::CheckerContext.new(cur_site, cur_user, contents, [], false, 0)

    contents.each do |content|
      if content["resolve"] == "html"
        checkers = Cms::SyntaxChecker.html_checkers
      else
        checkers = Cms::SyntaxChecker.text_checkers
      end

      Cms::SyntaxChecker::Base.each_html_with_index(content) do |html, idx|
        fragment = Nokogiri::HTML5.fragment(html)
        checkers.each do |checker|
          rescue_with do
            innstance = checker.new
            innstance.check(context, content["id"], idx, html, fragment)
          end
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
