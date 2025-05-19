class Cms::SyntaxChecker::IframeTitleChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('iframe').each do |iframe_node|
      title = iframe_node['title']
      next if title.present?

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(iframe_node),
        msg: I18n.t('errors.messages.set_iframe_title'),
        detail: I18n.t('errors.messages.syntax_check_detail.set_iframe_title')
      }
    end
  end
end
