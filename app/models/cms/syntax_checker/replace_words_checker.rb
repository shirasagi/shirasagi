class Cms::SyntaxChecker::ReplaceWordsChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    replace_words_conf = Cms::WordDictionary.site(context.cur_site).to_config
    replace_words = replace_words_conf[:replace_words]
    return if replace_words.blank?

    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      text = text_node.content.strip
      replace_words.each do |replace_from, replace_to|
        c = text.scan(replace_from)
        next if c.blank?

        context.errors << {
          id: id,
          idx: idx,
          code: c[0],
          ele: raw_html,
          msg: I18n.t('errors.messages.replace_word', from: replace_from, to: replace_to),
          collector: self.class.name,
          collector_params: {
            replace_from: replace_from,
            replace_to: replace_to,
          }
        }
      end
    end
  end

  def correct(context)
    replace_from = context.params["replace_from"]
    replace_to = context.params["replace_to"]
    return if replace_from.blank? || replace_to.blank?

    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)

      Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
        text_node.content = text_node.content.gsub(replace_from, replace_to)
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end
end
