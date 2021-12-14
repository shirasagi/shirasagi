class Cms::SyntaxChecker::TableChecker
  def self.check(context, id, idx, raw_html, doc)
    doc.search('//table').each do |table_node|
      caption = table_node.at_css('caption')
      if !caption || caption.text.strip.blank?
        context.errors << {
          id: id,
          idx: idx,
          code: outer_html_summary(table_node),
          msg: I18n.t('errors.messages.set_table_caption'),
          detail: I18n.t('errors.messages.syntax_check_detail.set_table_caption'),
          correctable: true
        }
      end

      table_node.search('//th').each do |th_node|
        next if th_node["scope"].present?

        context.errors << {
          id: id,
          idx: idx,
          code: outer_html_summary(th_node),
          msg: I18n.t('errors.messages.set_th_scope'),
          detail: I18n.t('errors.messages.syntax_check_detail.set_th_scope'),
          correctable: true
        }
      end
    end
  end

  def self.outer_html_summary(table_node)
    table_node.to_s.gsub(/[\r\n]|&nbsp;/, "")
  end
end
