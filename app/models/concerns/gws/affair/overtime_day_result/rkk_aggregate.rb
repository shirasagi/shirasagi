module Gws::Affair::OvertimeDayResult::RkkAggregate
  extend ActiveSupport::Concern

  module ClassMethods
    def rkk_aggregate
      prefs = {}

      aggregation = self.aggregate_partition
      aggregation.each do |user_id, files|
        files.each do |file_id, i|
          user_staff_address_uid = i[:user_staff_address_uid]
          project_code = i[:project_code]

          prefs[user_id] ||= {}
          prefs[user_id][user_staff_address_uid] ||= {}
          prefs[user_id][user_staff_address_uid][project_code] ||= {}

          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "duty_day_in_work_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["duty_day_time_minute"] += i[:under][:duty_day_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["duty_night_time_minute"] += i[:under][:duty_night_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["duty_day_in_work_time_minute"] += i[:under][:duty_day_in_work_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["leave_day_time_minute"] += i[:under][:leave_day_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["leave_night_time_minute"] += i[:under][:leave_night_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["week_out_compensatory_minute"] += i[:under][:week_out_compensatory_minute]
          prefs[user_id][user_staff_address_uid][project_code]["under_threshold"]["overtime_minute"] += i[:under][:overtime_minute]

          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"] ||= {
            "duty_day_time_minute" => 0,
            "duty_night_time_minute" => 0,
            "leave_day_time_minute" => 0,
            "leave_night_time_minute" => 0,
            "week_out_compensatory_minute" => 0,
            "overtime_minute" => 0
          }
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["duty_day_time_minute"] += i[:over][:duty_day_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["duty_night_time_minute"] += i[:over][:duty_night_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["leave_day_time_minute"] += i[:over][:leave_day_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["leave_night_time_minute"] += i[:over][:leave_night_time_minute]
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["week_out_compensatory_minute"] += i[:over][:week_out_compensatory_minute]
          prefs[user_id][user_staff_address_uid][project_code]["over_threshold"]["overtime_minute"] += i[:over][:overtime_minute]
        end
      end
      [prefs, aggregation]
    end
  end
end
