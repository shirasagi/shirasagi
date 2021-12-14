class Cms::SyntaxChecker::DateFormatChecker
  def self.check(context, id, idx, raw_html, doc)
    doc.search('//text()').each do |text_node|
      dates = text_node.text.scan(/\d{4}.\d{1,2}.\d{1,2}/)
      next if dates.blank?

      dates = dates.select { |date| valid_date?(date) }
      next if dates.blank?

      context.errors << {
        id: id,
        idx: idx,
        code: dates.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.invalid_date_format'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_date_format'),
        correctable: true
      }
    end
  end

  def self.valid_date?(date_like)
    date = date_like.in_time_zone rescue nil
    return false if !date

    date.year > 0
  end
end
