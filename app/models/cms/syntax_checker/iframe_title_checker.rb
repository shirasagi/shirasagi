class Cms::SyntaxChecker::IframeTitleChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    # iframe, frame, frameset frame をまとめて一度だけチェック
    context.fragment.css('iframe, frame, frameset frame').each do |node|
      title = node['title']
      title = title.strip if title
      code = Cms::SyntaxChecker::Base.outer_html_summary(node)

      check_presence(context, content, title, code)
      check_length(context, content, title, code)
      check_unfavorable_word(context, content, title, code)
    end
  end

  private

  def check_presence(context, content, title, code)
    return if title.present?

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :set_iframe_title)
  end

  def check_length(context, content, title, code)
    return if title.blank?
    return if context.link_text_min_length <= 0
    return if title.length >= context.link_text_min_length

    error = I18n.t("errors.messages.title_too_short", count: context.link_text_min_length)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
  end

  def check_unfavorable_word(context, content, title, code)
    return unless context.include_unfavorable_word?(title)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :unfavorable_word)
  end
end
