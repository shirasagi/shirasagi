class Cms::SyntaxChecker::ReplaceWordsChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, doc)
    replace_words_conf = Cms::WordDictionary.site(context.cur_site).to_config
    replace_words = replace_words_conf[:replace_words]
    return if replace_words.blank?

    doc.search('//text()').each do |text_node|
      text = text_node.text.strip
      replace_words.each do |replace_from, replace_to|
        c = text.scan(/#{::Regexp.escape(replace_from)}/)
        next if c.blank?

        context.errors << {
          id: id,
          idx: idx,
          code: c[0],
          ele: raw_html,
          msg: I18n.t('errors.messages.replace_word', from: replace_from, to: replace_to),
          collector: self.class.name,
          collector_params: {
            replaceKey: replace_from,
            replaceValue: replace_to,
          }
        }
      end
    end
  end
end
