class Cms::SyntaxChecker::KanaCharacterChecker
  def self.check(context, id, idx, raw_html, doc)
    chars = []
    doc.search('//text()').each do |text_node|
      chars += text_node.text.scan(/[｡-ﾟ]+/)
    end
    if chars.present?
      context.errors << {
        id: id,
        idx: idx,
        code: chars.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.invalid_kana_character'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_kana_character'),
        correctable: true
      }
    end
  end
end
