class Cms::SyntaxChecker::MultibyteCharacterChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, doc)
    chars = []
    doc.search('//text()').each do |text_node|
      chars += text_node.text.scan(/[Ａ-Ｚａ-ｚ０-９]+/)
    end
    if chars.present?
      context.errors << {
        id: id,
        idx: idx,
        code: chars.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.invalid_multibyte_character'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_multibyte_character'),
        collector: self.class.name
      }
    end
  end
end
