module Cms::SyntaxChecker
  module_function

  mattr_accessor :html_checkers, :text_checkers
  self.html_checkers = [
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker
  ]
  self.text_checkers = [
    Cms::SyntaxChecker::DateFormatChecker,
    Cms::SyntaxChecker::InterwordSpaceChecker,
    Cms::SyntaxChecker::KanaCharacterChecker,
    Cms::SyntaxChecker::MultibyteCharacterChecker,
    Cms::SyntaxChecker::ReplaceWordsChecker
  ]

  def check(cur_site:, cur_user:, contents:)
    context = Cms::SyntaxChecker::Context.new
    context.assign_attributes(cur_site: cur_site, cur_user: cur_user, contents: contents, errors: [])

    contents.each do |id, content|
      if content["resolve"] == "html"
        checkers = Cms::SyntaxChecker.html_checkers
      else
        checkers = Cms::SyntaxChecker.text_checkers
      end

      Cms::SyntaxChecker.each_html_with_index(content) do |html, idx|
        doc = Nokogiri::HTML.parse(html)
        checkers.each do |checker|
          checker.check(context, id, idx, html, doc)
        end
      end
    end

    context
  end

  def each_html_with_index(content, &block)
    value = content["content"]
    resolve = content["resolve"]

    if content["type"] == "array"
      value.each_with_index do |v, index|
        if resolve == "html"
          yield v, index
        else
          yield "<div>#{v}</div>", index
        end
      end
      return
    end

    if resolve == "html"
      yield value, 0
    else
      yield "<div>#{value}</div>", 0
    end
  end
end
