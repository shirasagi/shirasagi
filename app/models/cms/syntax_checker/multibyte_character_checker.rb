class Cms::SyntaxChecker::MultibyteCharacterChecker
  include Cms::SyntaxChecker::Base

  FULL_WIDTH_ALNUM_REGEX = /[Ａ-Ｚａ-ｚ０-９]+/.freeze

  def check(context, id, idx, raw_html, fragment)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      chars += text_node.content.scan(FULL_WIDTH_ALNUM_REGEX)
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
        text_node.content = text_node.content.gsub(FULL_WIDTH_ALNUM_REGEX) do |matched|
          matched.chars.map { |ch| (ch.ord - 0xFEE0).chr }.join
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end
end
