class Cms::SyntaxChecker::IframeTitleChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    # iframe, frame, frameset frame をまとめて一度だけチェック
    fragment.css('iframe, frame, frameset frame').each do |node|
      title = node['title']
      next if title.present?

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(node),
        msg: I18n.t('errors.messages.set_iframe_title'),
        detail: I18n.t('errors.messages.syntax_check_detail.set_iframe_title')
      }
    end
  end
end
