module SS::DateTimeHelper
  extend ActiveSupport::Concern

  def l_date(value, format: nil)
    return if value.blank?

    value = value.in_time_zone
    return if value.blank?

    I18n.l(value.to_date, format: format || :picker)
  end

  def l_time(value, format: nil)
    return if value.blank?

    value = value.in_time_zone
    return if value.blank?

    I18n.l(value, format: format || :picker)
  end

  def ss_time_tag(value, type: :time, **options)
    return if value.blank?

    value = value.in_time_zone rescue nil
    return if value.blank?

    value = value.to_date if type == :date
    format = options.delete(:format) || :picker

    options[:datetime] = value.respond_to?(:utc) ? value.utc.iso8601 : value.iso8601
    options[:title] = value.rfc2822

    tag.time(**options) do
      tag.span(I18n.l(value, format: format))
    end
  end
end
