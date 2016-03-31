module Gws::Schedule::Setting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :schedule_max_date, type: String

    permit_params :schedule_max_date
  end

  def schedule_max_date
    self[:schedule_max_date].presence || "fyear"
  end

  def schedule_max_at
    if schedule_max_date == "fyear1"
      Date.new (Time.zone.today << 3).year + 2, 3, 31
    else
      Date.new (Time.zone.today << 3).year + 1, 3, 31
    end
  end

  def schedule_max_date_options
    [
      [I18n.t("gws/schedule.options.max_date.fyear"), "fyear"],
      [I18n.t("gws/schedule.options.max_date.fyear1"), "fyear1"],
    ]
  end
end
