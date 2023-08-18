class Cms::SyntaxChecker::MultibyteCharacterChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      each_match(text_node.content) do |matched|
        matched = matched.to_s
        if matched.index(/[#{Cms::SyntaxChecker::FULL_AL_NUM_PAT}]/)
          chars << matched
        end
      end
    end
    if chars.present?
      context.errors << {
        id: id,
        idx: idx,
        code: chars.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.invalid_multibyte_character'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character'),
        collector: self.class.name
      }
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
