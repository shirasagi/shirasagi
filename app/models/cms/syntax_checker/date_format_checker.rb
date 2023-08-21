class Cms::SyntaxChecker::DateFormatChecker
  include Cms::SyntaxChecker::Base

  DATE_REGEX = /\d{4}[.\-\/]\d{1,2}[.\-\/]\d{1,2}/.freeze

  class << self
    def valid_date?(date_like)
      date = date_like.in_time_zone rescue nil
      return false if !date

      date.year > 0
    end
  end

  def check(context, id, idx, raw_html, fragment)
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      dates = text_node.content.scan(DATE_REGEX)
      next if dates.blank?

      dates = dates.select { |date| self.class.valid_date?(date) }
      next if dates.blank?

      context.errors << {
        id: id,
        idx: idx,
        code: dates.join(","),
        msg: I18n.t('errors.messages.invalid_date_format'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_date_format'),
        collector: self.class.name
      }
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html|
      fragment = Nokogiri::HTML5.fragment(html)

      Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
        text_node.content = text_node.content.gsub(DATE_REGEX) do |matched|
          if self.class.valid_date?(matched)
            I18n.l(matched.in_time_zone.to_date, format: :long)
          else
            matched
          end
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end
end
