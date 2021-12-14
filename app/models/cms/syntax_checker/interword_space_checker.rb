class Cms::SyntaxChecker::InterwordSpaceChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, doc)
    doc.search('//text()').each do |text_node|
      text = text_node.text.strip
      next if !text.include?('　')

      context.errors << {
        id: id,
        idx: idx,
        code: text,
        msg: I18n.t('errors.messages.check_interword_space'),
        detail: I18n.t('errors.messages.syntax_check_detail.check_interword_space')
      }
    end
  end
end
