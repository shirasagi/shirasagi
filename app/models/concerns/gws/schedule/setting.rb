module Gws::Schedule::Setting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :schedule_max_month, type: Integer
    field :schedule_max_years, type: Integer

    permit_params :schedule_max_month, :schedule_max_years
  end

  def schedule_max_month
    self[:schedule_max_month].presence || 3
  end

  def schedule_max_years
    self[:schedule_max_years].presence || 1
  end

  def schedule_max_at
    year = (Time.zone.today << schedule_max_month).year + schedule_max_years + 1
    Date.new year, schedule_max_month, -1
  end

  def schedule_max_month_options
    1..12
  end

  def schedule_max_years_options
    (0..10).map { |m| ["+#{m}", m] }
  end
end
