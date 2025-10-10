class Cms::SyntaxChecker::KanaCharacterChecker
  include Cms::SyntaxChecker::Base

  HALF_WIDTH_KANA_REGX = /[｡-ﾟ]+/.freeze

  def check(context, content)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(context.fragment) do |text_node|
      chars += text_node.content.scan(HALF_WIDTH_KANA_REGX)
    end
    if chars.present?
      code = chars.join(",")
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :invalid_kana_character,
        corrector: self.class.name)
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)

      Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
        text_node.content = text_node.content.gsub(HALF_WIDTH_KANA_REGX) do |matched|
          # NKF.nkf('-w -X', matched)
          matched.unicode_normalize(:nfkc)
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end

  def correct2(content, params: nil)
    fragment = Nokogiri::HTML5.fragment(content)

    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      text_node.content = text_node.content.gsub(HALF_WIDTH_KANA_REGX) do |matched|
        # NKF.nkf('-w -X', matched)
        matched.unicode_normalize(:nfkc)
      end
    end

    fragment.to_html
  end
end
