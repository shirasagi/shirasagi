class Opendata::DownloadReport
  include ActiveModel::Model

  attr_accessor :period, :start_year, :start_month, :end_year, :end_month, :type

  validate :start_is_new_date_than_end

  def years
    sy = Time.zone.today.year - 10
    ey = Time.zone.today.year
    (sy..ey).to_a.reverse.map { |d| ["#{d}#{I18n.t('datetime.prompts.year')}", d] }
  end

  def months
    (1..12).to_a.map { |d| ["#{d}#{I18n.t('datetime.prompts.month')}", d] }
  end

  def types
    [:day, :month, :year].map { |t| [self.class.human_attribute_name("type.#{t}"), t]}
  end

  private

  def start_is_new_date_than_end
    start_date = Time.zone.local(start_year, start_month)
    end_date = Time.zone.local(end_year, end_month)

    if start_date > end_date
      errors.add :base, :period
    end
  end

end
