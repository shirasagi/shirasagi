module Gws::Affair::OvertimeDayResult::UserAggregate
  extend ActiveSupport::Concern

  module ClassMethods
    def user_aggregate
      prefs = {}

      aggregation = self.aggregate_partition
      aggregation.each do |user_id, files|
        files.each do |file_id, i|
          capital_code = i[:capital_code]

          prefs[user_id] ||= {}
          prefs[user_id]["total"] ||= {}
          prefs[user_id][capital_code] ||= {}

          prefs[user_id][capital_code]["under_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "duty_day_in_work_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id][capital_code]["under_threshold"]["duty_day_time_minute"] += i[:under][:duty_day_time_minute]
          prefs[user_id][capital_code]["under_threshold"]["duty_night_time_minute"] += i[:under][:duty_night_time_minute]
          prefs[user_id][capital_code]["under_threshold"]["duty_day_in_work_time_minute"] += i[:under][:duty_day_in_work_time_minute]
          prefs[user_id][capital_code]["under_threshold"]["leave_day_time_minute"] += i[:under][:leave_day_time_minute]
          prefs[user_id][capital_code]["under_threshold"]["leave_night_time_minute"] += i[:under][:leave_night_time_minute]
          prefs[user_id][capital_code]["under_threshold"]["week_out_compensatory_minute"] += i[:under][:week_out_compensatory_minute]
          prefs[user_id][capital_code]["under_threshold"]["overtime_minute"] += i[:under][:overtime_minute]

          prefs[user_id]["total"]["under_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "duty_day_in_work_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id]["total"]["under_threshold"]["duty_day_time_minute"] += i[:under][:duty_day_time_minute]
          prefs[user_id]["total"]["under_threshold"]["duty_night_time_minute"] += i[:under][:duty_night_time_minute]
          prefs[user_id]["total"]["under_threshold"]["duty_day_in_work_time_minute"] += i[:under][:duty_day_in_work_time_minute]
          prefs[user_id]["total"]["under_threshold"]["leave_day_time_minute"] += i[:under][:leave_day_time_minute]
          prefs[user_id]["total"]["under_threshold"]["leave_night_time_minute"] += i[:under][:leave_night_time_minute]
          prefs[user_id]["total"]["under_threshold"]["week_out_compensatory_minute"] += i[:under][:week_out_compensatory_minute]
          prefs[user_id]["total"]["under_threshold"]["overtime_minute"] += i[:under][:overtime_minute]

          prefs[user_id][capital_code]["over_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id][capital_code]["over_threshold"]["duty_day_time_minute"] += i[:over][:duty_day_time_minute]
          prefs[user_id][capital_code]["over_threshold"]["duty_night_time_minute"] += i[:over][:duty_night_time_minute]
          prefs[user_id][capital_code]["over_threshold"]["leave_day_time_minute"] += i[:over][:leave_day_time_minute]
          prefs[user_id][capital_code]["over_threshold"]["leave_night_time_minute"] += i[:over][:leave_night_time_minute]
          prefs[user_id][capital_code]["over_threshold"]["week_out_compensatory_minute"] += i[:over][:week_out_compensatory_minute]
          prefs[user_id][capital_code]["over_threshold"]["overtime_minute"] += i[:over][:overtime_minute]

          prefs[user_id]["total"]["over_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id]["total"]["over_threshold"]["duty_day_time_minute"] += i[:over][:duty_day_time_minute]
          prefs[user_id]["total"]["over_threshold"]["duty_night_time_minute"] += i[:over][:duty_night_time_minute]
          prefs[user_id]["total"]["over_threshold"]["leave_day_time_minute"] += i[:over][:leave_day_time_minute]
          prefs[user_id]["total"]["over_threshold"]["leave_night_time_minute"] += i[:over][:leave_night_time_minute]
          prefs[user_id]["total"]["over_threshold"]["week_out_compensatory_minute"] += i[:over][:week_out_compensatory_minute]
          prefs[user_id]["total"]["over_threshold"]["overtime_minute"] += i[:over][:overtime_minute]
        end
      end
      [prefs, aggregation]
    end
  end
end
