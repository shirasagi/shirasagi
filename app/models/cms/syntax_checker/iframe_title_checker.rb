class Cms::SyntaxChecker::IframeTitleChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    # frameset内のframeタグも検出できるように、より詳細なセレクタを使用
    fragment.css('frame, frameset frame').each do |node|
      check_node(context, id, idx, node)
    end

    fragment.css('iframe').each do |node|
      check_node(context, id, idx, node)
    end
  end

  private

  def check_node(context, id, idx, node)
    title = node['title']
    return if title.present?

    context.errors << {
      id: id,
      idx: idx,
      code: Cms::SyntaxChecker::Base.outer_html_summary(node),
      msg: I18n.t('errors.messages.set_iframe_title'),
      detail: I18n.t('errors.messages.syntax_check_detail.set_iframe_title')
    }
  end
end
