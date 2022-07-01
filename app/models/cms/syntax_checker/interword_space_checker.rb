class Cms::SyntaxChecker::InterwordSpaceChecker
  include Cms::SyntaxChecker::Base

  # rubocop:disable Lint/UnreachableLoop
  def check(context, id, idx, raw_html, fragment)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      text = text_node.content.strip
      each_match(text) do |_matched_position|
        chars << text
        # 1 つの text に対して、一度しか報告しないようにする
        break
      end
    end
    if chars.present?
      context.errors << {
        id: id,
        idx: idx,
        code: chars.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.check_interword_space'),
        detail: I18n.t('errors.messages.syntax_check_detail.check_interword_space'),
        collector: self.class.name
      }
    end
  end
  # rubocop:enable Lint/UnreachableLoop

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)

      Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
        text = text_node.content.strip
        each_match(text) do |matched_position|
          text[matched_position] = Cms::SyntaxChecker::SP
        end
        text_node.content = text
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end

  private

  def each_match(text)
    pos = 0
    loop do
      matched = text.index(Cms::SyntaxChecker::FULL_WIDTH_SPACE, pos)
      break if matched.nil?

      yield matched if half_width?(text[matched - 1]) || half_width?(text[matched + 1])

      pos = matched + 1
    end
  end

  def half_width?(chr)
    return true if chr.blank?

    cp = chr.codepoints
    return false if cp.length > 1

    cp = cp[0]
    cp <= 0x7f
  end
end
