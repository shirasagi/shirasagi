class Cms::SyntaxChecker::ImgAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('img').each do |img_node|
      code = Cms::SyntaxChecker::Base.outer_html_summary(img_node)

      alt = img_node["alt"]
      alt = alt.strip if alt
      check_alt_presence(context, content, alt, code)
      check_alt_length(context, content, alt, code)
      check_alt_unfavorable_word(context, content, alt, code)

      src = img_node["src"]
      src = src.strip if src
      check_src(context, content, alt, src, code)
    end
  end

  private

  def check_alt_presence(context, content, alt, code)
    return if alt.present?

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :set_img_alt)
  end

  def check_alt_length(context, content, alt, code)
    return if alt.blank?
    return if context.link_text_min_length <= 0
    return if alt.length >= context.link_text_min_length

    error = I18n.t("errors.messages.alt_too_short", count: context.link_text_min_length)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
  end

  def check_alt_unfavorable_word(context, content, alt, code)
    return if alt.blank?
    return unless context.include_unfavorable_word?(alt)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :unfavorable_word)
  end

  def check_src(context, content, alt, src, code)
    return if alt.blank?
    return if src.blank?
    return unless src.downcase.include?(alt.downcase)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :alt_is_included_in_filename)
  end
end
