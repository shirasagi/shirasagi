class Cms::SyntaxChecker::IframeTitleChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    # iframe, frame, frameset frame をまとめて一度だけチェック
    context.fragment.css('iframe, frame, frameset frame').each do |node|
      title = node['title']
      next if title.present?

      code = Cms::SyntaxChecker::Base.outer_html_summary(node)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :set_iframe_title)
    end
  end
end
