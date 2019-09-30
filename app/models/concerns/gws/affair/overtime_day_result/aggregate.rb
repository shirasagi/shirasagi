module Gws::Affair::OvertimeDayResult::Aggregate
  extend ActiveSupport::Concern
  include Gws::Affair::OvertimeDayResult::UserAggregate
  include Gws::Affair::OvertimeDayResult::CapitalAggregate
  include Gws::Affair::OvertimeDayResult::RkkAggregate

  module ClassMethods
    def aggregate_partition(opts = {})
      unclosed_file_ids = opts[:unclosed_file_ids].to_a
      match_pipeline = self.criteria.selector
      group_pipeline = {
        _id: {
          site_id: "$site_id",
          result_closed: "$result_closed",

          # user
          user_id: "$target_user_id",
          user_code: "$target_user_code",
          user_staff_address_uid: "$target_user_staff_address_uid",

          # group
          group_id: "$target_group_id",
          group_code: "$target_group_code",

          # date
          date: "$date",
          fiscal_year: "$date_fiscal_year",
          month: "$date_month",
          start_at: "$start_at",
          end_at: "$end_at",

          # capital
          capital_code: "$capital_basic_code",
          project_code: "$capital_project_code",
          detail_code: "$capital_detail_code",
          file_id: "$file_id",
        },
        duty_day_time_minute: { "$sum" => "$duty_day_time_minute" },
        duty_night_time_minute: { "$sum" => "$duty_night_time_minute" },
        duty_day_in_work_time_minute: { "$sum" => "$duty_day_in_work_time_minute" },
        leave_day_time_minute: { "$sum" => "$leave_day_time_minute" },
        leave_night_time_minute: { "$sum" => "$leave_night_time_minute" },
        week_in_compensatory_minute: { "$sum" => "$week_in_compensatory_minute" },
        week_out_compensatory_minute: { "$sum" => "$week_out_compensatory_minute" },
        holiday_compensatory_minute: { "$sum" => "$holiday_compensatory_minute" },
        break_time_minute: { "$sum" => "$break_time_minute" },
      }

      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => { "_id.date" => 1 } }

      threshold = SS.config.gws.affair.dig("overtime", "aggregate", "threshold_hour") * 60
      week_working_extractor = Gws::Affair::WeekWorkingExtractor.new

      prefs = {}
      subtractors = {}

      aggregation = Gws::Affair::OvertimeDayResult.collection.aggregate(pipes)
      aggregation.each do |i|
        site_id = i["_id"]["site_id"]
        result_closed = i["_id"]["result_closed"]
        user_id = i["_id"]["user_id"]
        user_code = i["_id"]["user_code"]
        user_staff_address_uid = i["_id"]["user_staff_address_uid"]
        group_id = i["_id"]["group_id"]
        group_code = i["_id"]["group_code"]
        date = i["_id"]["date"]
        fiscal_year = i["_id"]["fiscal_year"]
        month = i["_id"]["month"]
        start_at = i["_id"]["start_at"]
        end_at = i["_id"]["end_at"]
        capital_code = i["_id"]["capital_code"]
        project_code = i["_id"]["project_code"]
        detail_code = i["_id"]["detail_code"]
        file_id = i["_id"]["file_id"]

        duty_day_time_minute = i["duty_day_time_minute"]
        duty_day_in_work_time_minute = i["duty_day_in_work_time_minute"]
        duty_night_time_minute = i["duty_night_time_minute"]

        leave_day_time_minute = i["leave_day_time_minute"]
        leave_night_time_minute = i["leave_night_time_minute"]

        week_in_compensatory_minute = i["week_in_compensatory_minute"]
        holiday_compensatory_minute = i["holiday_compensatory_minute"]
        break_time_minute = i["break_time_minute"]

        unrate_week_out_compensatory_minute = i["week_out_compensatory_minute"]
        week_out_compensatory_minute = 0

        # 結果が確定していない為、集計対象外
        if !unclosed_file_ids.include?(file_id)
          next if result_closed.blank?
        end

        # 週内、週外残業（土日）があった場合、休出区分割増にならない
        if week_in_compensatory_minute > 0 || unrate_week_out_compensatory_minute > 0
          duty_day_time_minute += leave_day_time_minute
          duty_night_time_minute += leave_night_time_minute

          leave_day_time_minute = 0
          leave_night_time_minute = 0
        end

        # 週外残業は、その週の業務時間合計が 38.75h (2325m) を超えない場合、割増がつかない
        if unrate_week_out_compensatory_minute > 0
          week_working = week_working_extractor.week_at(site_id, user_id, date.to_date)
          week_working_minute = week_working.map { |v| v[:working_minutes] }.sum

          if week_working_minute >= 2325
            unrate_week_out_compensatory_minute = 0
            week_out_compensatory_minute = i["week_out_compensatory_minute"]
          end
        end

        subtractors[user_id] ||= Gws::Affair::Subtractor.new(threshold)
        prefs[user_id] ||= {}

        w_c_m = week_out_compensatory_minute # 0. 025/100
        i_w_m = duty_day_in_work_time_minute # 1. 100/100
        d_d_m = duty_day_time_minute         # 2. 125/100
        l_d_m = leave_day_time_minute        # 3. 135/100
        d_n_m = duty_night_time_minute       # 4. 150/100
        l_n_m = leave_night_time_minute      # 5. 160/100

        under_minutes, over_minutes = subtractors[user_id].subtract(w_c_m, i_w_m, d_d_m, l_d_m, d_n_m, l_n_m)

        under_overtime_minute = under_minutes.sum
        over_overtime_minute = over_minutes.sum
        overtime_minute = under_overtime_minute + over_overtime_minute

        prefs[user_id][file_id] = {
          # user
          user_id: user_id,
          user_code: user_code,
          user_staff_address_uid: user_staff_address_uid,

          # group
          group_id: group_id,
          group_code: group_code,

          # date
          date: date.localtime,
          fiscal_year: fiscal_year,
          month: month,
          start_at: start_at.localtime,
          end_at: end_at.localtime,

          # capital
          capital_code: capital_code,
          project_code: project_code,
          detail_code: detail_code,

          # minutes
          week_in_compensatory_minute: week_in_compensatory_minute,
          holiday_compensatory_minute: holiday_compensatory_minute,
          week_out_compensatory_minute: week_out_compensatory_minute,
          unrate_week_out_compensatory_minute: unrate_week_out_compensatory_minute,
          break_time_minute: break_time_minute,
          week_working: week_working,
          overtime_minute: overtime_minute,
          under: {
            duty_day_time_minute: under_minutes[2].to_i,
            duty_night_time_minute: under_minutes[4].to_i,
            duty_day_in_work_time_minute: under_minutes[1].to_i,
            leave_day_time_minute: under_minutes[3].to_i,
            leave_night_time_minute: under_minutes[5].to_i,
            week_out_compensatory_minute: under_minutes[0].to_i,
            overtime_minute: under_overtime_minute
          },
          over: {
            duty_day_time_minute: (over_minutes[2].to_i + over_minutes[1].to_i),
            duty_night_time_minute: over_minutes[4].to_i,
            leave_day_time_minute: over_minutes[3].to_i,
            leave_night_time_minute: over_minutes[5].to_i,
            week_out_compensatory_minute: over_minutes[0].to_i,
            overtime_minute: over_overtime_minute
          }
        }
      end
      prefs
    end
  end
end
