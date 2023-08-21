module Gws::Addon::System::FiscalYearSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  set_addon_type :organization

  included do
    field :fiscal_year_changed_month, type: Integer, default: 4
    permit_params :fiscal_year_changed_month

    validates :fiscal_year_changed_month, numericality: true
  end

  def fiscal_year_changed_month_options
    (1..12).map do |m|
      [ "#{m}#{I18n.t('datetime.prompts.month')}", m.to_s ]
    end
  end

  def fiscal_year(now = Time.zone.now)
    now.month >= fiscal_year_changed_month ? now.year : (now.year - 1)
  end

  def fiscal_first_date(fyear = fiscal_year)
    Time.zone.parse("#{fyear}/#{fiscal_year_changed_month}/1")
  end

  def fiscal_last_date(fyear = fiscal_year)
    Time.zone.parse("#{fyear + 1}/#{fiscal_year_changed_month}/1").advance(days: -1)
  end

  def fiscal_months
    (fiscal_year_changed_month..12).to_a + (1...fiscal_year_changed_month).to_a
  end
end
