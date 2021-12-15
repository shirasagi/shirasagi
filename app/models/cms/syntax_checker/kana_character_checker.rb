class Cms::SyntaxChecker::KanaCharacterChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, doc)
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
        collector: self.class.name
      }
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker.each_html_with_index(context.content) do |html, index|
      doc = Nokogiri::HTML.parse(html)

      doc.search('//text()').each do |text_node|
        text_node.content = text_node.content.gsub(/[｡-ﾟ]/) do |matched|
          # NKF.nkf('-w -X', matched)
          matched.unicode_normalize(:nfkc)
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
