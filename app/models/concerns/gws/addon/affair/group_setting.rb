module Gws::Addon::Affair::GroupSetting
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Affair::DutyHourSetting

  set_addon_type :organization

  included do
    field :compensatory_minute1, type: Integer, default: 240
    field :compensatory_minute2, type: Integer, default: 465
    field :compensatory_minute3, type: Integer

    field :week_out_compensatory_file_start_limit, type: Integer, default: 4
    field :week_out_compensatory_file_start_limit_unit, type: String, default: 'week'
    field :week_out_compensatory_file_end_limit, type: Integer, default: 8
    field :week_out_compensatory_file_end_limit_unit, type: String, default: 'week'
    field :week_out_compensatory_file_notify_day, type: Integer, default: 7

    permit_params :compensatory_minute1
    permit_params :compensatory_minute2
    permit_params :compensatory_minute3
    permit_params :week_out_compensatory_file_start_limit
    permit_params :week_out_compensatory_file_start_limit_unit
    permit_params :week_out_compensatory_file_end_limit
    permit_params :week_out_compensatory_file_end_limit_unit
    permit_params :week_out_compensatory_file_notify_day
  end

  def compensatory_minute1_options
    29.times.map { |i| 60 + (i * 15) }.map do |m|
      ["#{m.to_f / 60}#{I18n.t("ss.hours")}", m]
    end
  end

  def compensatory_minute_options
    [
      compensatory_minute1,
      compensatory_minute2,
      compensatory_minute3
    ].compact.map do |m|
      ["#{m.to_f / 60}#{I18n.t("ss.hours")}", m]
    end
  end

  def week_out_compensatory_file_start_limit_unit_options
    %w(day week month year).collect do |unit|
      [I18n.t("ss.options.datetime_unit.#{unit}"), unit]
    end
  end

  alias week_out_compensatory_file_end_limit_unit_options week_out_compensatory_file_start_limit_unit_options
  alias compensatory_minute2_options compensatory_minute1_options
  alias compensatory_minute3_options compensatory_minute1_options
end
