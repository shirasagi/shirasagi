class Cms::SyntaxChecker::LinkTextChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css("a[href]").each do |a_node|
      code = Cms::SyntaxChecker::Base.outer_html_summary(a_node)

      text = Cms::SyntaxChecker::Base.extract_a11y_label(context, a_node)
      if text
        text = text.strip
      else
        text = ""
      end

      check_unfavorable_word(context, content, text, code)
      check_length(context, content, text, code)
    end
  end

  private

  def check_unfavorable_word(context, content, text, code)
    return if text.blank?
    return unless context.include_unfavorable_word?(text)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :unfavorable_word)
  end

  def check_length(context, content, text, code)
    return if text.blank?
    return if context.link_text_min_length <= 0
    return if text.length >= context.link_text_min_length

    error = I18n.t("errors.messages.link_text_too_short", count: context.link_text_min_length)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
  end
end
