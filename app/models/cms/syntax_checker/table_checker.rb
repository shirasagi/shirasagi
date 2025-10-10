class Cms::SyntaxChecker::TableChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('table').each do |table_node|
      check_caption(context, content, table_node)
      check_unscoped_th(context, content, table_node)
    end
  end

  def correct(context)
    return if context.params.blank?

    case context.params['tag']
    when 'caption'
      correct_caption(context)
    when 'th'
      correct_th_scope(context)
    end
  end

  def correct2(content, params:)
    case params['tag']
    when 'caption'
      correct_caption2(content)
    when 'th'
      correct_th_scope2(content)
    end
  end

  private

  def check_caption(context, content, table_node)
    caption = table_node.at_css('caption')
    return if caption && caption.text.strip.present?

    code = Cms::SyntaxChecker::Base.outer_html_summary(table_node)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :set_table_caption,
      corrector: self.class.name, corrector_params: { tag: 'caption' })
  end

  def check_unscoped_th(context, content, table_node)
    tr_nodes = table_node.css('tr').to_a
    unscoped_nodes = tr_nodes.select { |tr_node| include_unscoped_th?(tr_node) }
    return if unscoped_nodes.blank?

    code = unscoped_nodes.map { |node| Cms::SyntaxChecker::Base.outer_html_summary(node) }.join(",")
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :set_th_scope,
      corrector: self.class.name, corrector_params: { tag: 'th' })
  end

  def include_unscoped_th?(tr_node)
    th_nodes = tr_node.css('th')
    return false if th_nodes.blank?

    th_nodes.any? { |th_node| th_node["scope"].blank? }
  end

  def correct_caption(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css('table').each do |table_node|
        caption = table_node.at_css('caption')
        next if caption && caption.content.present?

        if !caption
          caption = Nokogiri::XML::Node::new('caption', table_node.document)
          table_node.prepend_child(caption)
        end

        caption.content = I18n.t('cms.auto_correct.caption')
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end

  def correct_caption2(content)
    fragment = Nokogiri::HTML5.fragment(content)

    fragment.css('table').each do |table_node|
      caption = table_node.at_css('caption')
      next if caption && caption.content.present?

      if !caption
        caption = Nokogiri::XML::Node::new('caption', table_node.document)
        table_node.prepend_child(caption)
      end

      caption.content = I18n.t('cms.auto_correct.caption')
    end

    fragment.to_html
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

  def correct_th_scope2(content)
    fragment = Nokogiri::HTML5.fragment(content)

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

    fragment.to_html
  end
end
