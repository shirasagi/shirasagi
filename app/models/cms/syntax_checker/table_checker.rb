class Cms::SyntaxChecker::TableChecker
  include Cms::SyntaxChecker::Base

  class << self
    def outer_html_summary(table_node)
      table_node.to_s.gsub(/[\r\n]|&nbsp;/, "")
    end
  end

  def check(context, id, idx, raw_html, doc)
    doc.search('//table').each do |table_node|
      caption = table_node.at_css('caption')
      if !caption || caption.text.strip.blank?
        context.errors << {
          id: id,
          idx: idx,
          code: self.class.outer_html_summary(table_node),
          msg: I18n.t('errors.messages.set_table_caption'),
          detail: I18n.t('errors.messages.syntax_check_detail.set_table_caption'),
          collector: self.class.name,
          collector_params: {
            tag: 'caption'
          }
        }
      end

      table_node.search('//th').each do |th_node|
        next if th_node["scope"].present?

        context.errors << {
          id: id,
          idx: idx,
          code: self.class.outer_html_summary(th_node),
          msg: I18n.t('errors.messages.set_th_scope'),
          detail: I18n.t('errors.messages.syntax_check_detail.set_th_scope'),
          collector: self.class.name,
          collector_params: {
            tag: 'th'
          }
        }
      end
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

  private

  def correct_caption(context)
    ret = []

    Cms::SyntaxChecker.each_html_with_index(context.content) do |html, index|
      doc = Nokogiri::HTML.parse(html)
      doc.search('//table').each do |table_node|
        caption = table_node.at_css('caption')
        next if caption && caption.content.present?

        if !caption
          caption = Nokogiri::XML::Node::new('caption', doc)
          table_node.prepend_child(caption)
        end

        caption.content = I18n.t('cms.auto_correct.caption')
      end

      ret << doc.at('body').at('div').inner_html.strip
    end

    if context.content["type"] == "array"
      context.result = ret
    else
      context.result = ret[0]
    end
  end

  def correct_th_scope(context)
    ret = []

    Cms::SyntaxChecker.each_html_with_index(context.content) do |html, index|
      doc = Nokogiri::HTML.parse(html)
      doc.search('//table').each do |table_node|
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

      ret << doc.at('body').at('div').inner_html.strip
    end

    if context.content["type"] == "array"
      context.result = ret
    else
      context.result = ret[0]
    end
  end
end
