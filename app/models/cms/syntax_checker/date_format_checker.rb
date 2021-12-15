class Cms::SyntaxChecker::DateFormatChecker
  include Cms::SyntaxChecker::Base

  class << self
    def valid_date?(date_like)
      date = date_like.in_time_zone rescue nil
      return false if !date

      date.year > 0
    end
  end

  def check(context, id, idx, raw_html, doc)
    doc.search('//text()').each do |text_node|
      dates = text_node.text.scan(/\d{4}.\d{1,2}.\d{1,2}/)
      next if dates.blank?

      dates = dates.select { |date| self.class.valid_date?(date) }
      next if dates.blank?

      context.errors << {
        id: id,
        idx: idx,
        code: dates.join(","),
        ele: raw_html,
        msg: I18n.t('errors.messages.invalid_date_format'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_date_format'),
        collector: self.class.name
      }
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker.each_html_with_index(context.content) do |html, index|
      doc = Nokogiri::HTML.parse(html)

      doc.search('//text()').each do |text_node|
        text_node.content = text_node.content.gsub(/\d{4}.\d{1,2}.\d{1,2}/) do |matched|
          if self.class.valid_date?(matched)
            I18n.l(matched.in_time_zone.to_date, format: :long)
          else
            matched
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
