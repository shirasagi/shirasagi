class Cms::SyntaxChecker::MultibyteCharacterChecker
  include Cms::SyntaxChecker::Base

  SP = " ".freeze
  FULL_WIDTH_SPACE = Cms::SyntaxChecker::InterwordSpaceChecker::FULL_WIDTH_SPACE
  FULL_AL_NUM_PAT = "Ａ-Ｚａ-ｚ０-９".freeze
  AL_NUM_PAT = "A-Za-z0-9#{FULL_AL_NUM_PAT}".freeze
  AL_NUM_SP_PAT = "#{AL_NUM_PAT}#{SP}#{FULL_WIDTH_SPACE}".freeze
  AL_NUM_REGEX = /[#{AL_NUM_PAT}]([#{AL_NUM_SP_PAT}]*[#{AL_NUM_PAT}])?/.freeze

  def check(context, id, idx, raw_html, fragment)
    chars = []
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      each_match(text_node.content) do |matched|
        matched = matched.to_s
        if matched.index(/[#{FULL_AL_NUM_PAT}#{FULL_WIDTH_SPACE}]/)
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
        text_node.content = text_node.content.gsub(AL_NUM_REGEX) do |matched|
          matched.to_s.tr("Ａ-Ｚａ-ｚ０-９#{FULL_WIDTH_SPACE}", "A-Za-z0-9#{SP}")
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
      matched = AL_NUM_REGEX.match(text, pos)
      break if matched.nil?

      yield matched

      pos = matched.end(0) + 1
    end
  end
end
