class Cms::SyntaxChecker::TableChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('table').each do |table_node|
      check_caption(context, id, idx, table_node)
      check_unscoped_th(context, id, idx, table_node)
    end
  end

  def correct(context)
    Rails.logger.debug "[DEBUG][TableChecker] correctメソッド呼び出し: params=#{context.params.inspect}, content=#{context.content.inspect}"
    return if context.params.blank?

    case context.params['tag']
    when 'caption'
      correct_caption(context)
    when 'th'
      correct_th_scope(context)
    end
  end

  private

  def check_caption(context, id, idx, table_node)
    caption = table_node.at_css('caption')
    return if caption && caption.text.strip.present?

    context.errors << {
      id: id,
      idx: idx,
      code: Cms::SyntaxChecker::Base.outer_html_summary(table_node),
      msg: I18n.t('errors.messages.set_table_caption'),
      detail: I18n.t('errors.messages.syntax_check_detail.set_table_caption'),
      collector: self.class.name,
      collector_params: {
        tag: 'caption'
      }
    }
  end

  def check_unscoped_th(context, id, idx, table_node)
    tr_nodes = table_node.css('tr').to_a
    unscoped_nodes = tr_nodes.select { |tr_node| include_unscoped_th?(tr_node) }
    return if unscoped_nodes.blank?

    code = unscoped_nodes.map { |node| Cms::SyntaxChecker::Base.outer_html_summary(node) }.join(",")
    context.errors << {
      id: id,
      idx: idx,
      code: code,
      msg: I18n.t('errors.messages.set_th_scope'),
      detail: I18n.t('errors.messages.syntax_check_detail.set_th_scope'),
      collector: self.class.name,
      collector_params: {
        tag: 'th'
      }
    }
  end

  def include_unscoped_th?(tr_node)
    th_nodes = tr_node.css('th')
    return false if th_nodes.blank?

    th_nodes.any? { |th_node| th_node["scope"].blank? }
  end

  def correct_caption(context)
    Rails.logger.debug "[DEBUG][TableChecker] correct_captionメソッド呼び出し: content=#{context.content.inspect}"
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      Rails.logger.debug "[DEBUG][TableChecker] each_html_with_index: html=#{html.inspect}, index=#{index}"
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css('table').each do |table_node|
        Rails.logger.debug "[DEBUG][TableChecker] table_node(before): #{table_node.to_html}"
        caption = table_node.at_css('caption')
        next if caption && caption.content.present?

        if !caption
          caption = Nokogiri::XML::Node::new('caption', table_node.document)
          table_node.prepend_child(caption)
        end

        caption.content = I18n.t('cms.auto_correct.caption')
        Rails.logger.debug "[DEBUG][TableChecker] table_node(after): #{table_node.to_html}"
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
      Rails.logger.debug "[DEBUG][TableChecker] inner_html_within_div: #{ret.last.inspect}"
    end

    context.set_result(ret)
    Rails.logger.debug "[DEBUG][TableChecker] set_result: #{ret.inspect}"
  end

  def correct_th_scope(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css('table').each do |table_node|
        scope = table_node.css("tr:first th").count == 1 ? "row" : "col"

        table_node.css("tr:first th").each do |th_node|
          if th_node["scope"].blank?
            th_node["scope"] = scope
          end
        end
        table_node.css("tr:not(:first) th").each do |th_node|
          if th_node["scope"].blank?
            th_node["scope"] = "row"
          end
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end
end
