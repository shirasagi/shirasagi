class Cms::SyntaxChecker::AreaAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('area').each do |area_node|
      alt = area_node["alt"]
      alt = alt.strip if alt
      code = Cms::SyntaxChecker::Base.outer_html_summary(area_node)
      check_presence(context, content, alt, code)
      check_length(context, content, alt, code)
      check_unfavorable_word(context, content, alt, code)
    end
  end

  private

  def check_presence(context, content, alt, code)
    return if alt.present?

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :set_area_alt)
  end

  def check_length(context, content, alt, code)
    return if alt.blank?
    return if context.link_text_min_length <= 0

    return if alt.length >= context.link_text_min_length

    error = I18n.t("errors.messages.alt_too_short", count: context.link_text_min_length)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
  end

  def check_unfavorable_word(context, content, alt, code)
    return if alt.blank?
    return unless context.include_unfavorable_word?(alt)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :unfavorable_word)
  end
end
