class Cms::SyntaxChecker::MultibyteCharacterChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(context.fragment) do |text_node|
      each_match(text_node.content) do |matched|
        matched = matched.to_s
        if matched.index(/[#{Cms::SyntaxChecker::FULL_AL_NUM_PAT}]/)
          chars << matched
        end
      end
    end
    if chars.present?
      code = chars.join(",")
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :invalid_multibyte_character,
        corrector: self.class.name)
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)

      Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
        text_node.content = text_node.content.gsub(Cms::SyntaxChecker::AL_NUM_REGEX) do |matched|
          matched.to_s.tr(Cms::SyntaxChecker::FULL_AL_NUM_PAT, Cms::SyntaxChecker::HALF_AL_NUM_PAT)
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end

  def correct2(content, params: nil)
    fragment = Nokogiri::HTML5.fragment(content)

    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      text_node.content = text_node.content.gsub(Cms::SyntaxChecker::AL_NUM_REGEX) do |matched|
        matched.to_s.tr(Cms::SyntaxChecker::FULL_AL_NUM_PAT, Cms::SyntaxChecker::HALF_AL_NUM_PAT)
      end
    end

    fragment.to_html
  end

  private

  def each_match(text)
    pos = 0
    loop do
      matched = Cms::SyntaxChecker::AL_NUM_REGEX.match(text, pos)
      break if matched.nil?

      yield matched

      pos = matched.end(0) + 1
    end
  end
end
