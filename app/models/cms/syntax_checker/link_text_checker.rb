class Cms::SyntaxChecker::LinkTextChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css("a[href]").each do |a_node|
      text = a_node.text
      if text.length <= 3
        img_node = a_node.at_css("img[alt]")
        if img_node
          text = img_node["alt"]
        end
      end
      text = text.strip if text
      next if text.length > 3

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(a_node),
        msg: I18n.t('errors.messages.check_link_text'),
        detail: I18n.t('errors.messages.syntax_check_detail.check_link_text')
      }
    end
  end
end
