module Gws::Affair::Aggregator
  class Partition
    attr_reader :match_pipeline

    def model
      Gws::Affair::OvertimeDayResult
    end

    def initialize(criteria)
      @match_pipeline = criteria.selector
    end

    def aggregate_partition(opts = {})
      @prefs = {}
      @subtractors = {}
      @unclosed_file_ids = opts[:unclosed_file_ids].to_a
      @week_working_extractor = WeekWorkingExtractor.new

      pipes = []
      pipes << { "$match" => match_pipeline }
      pipes << { "$group" => group_pipeline }
      pipes << { "$sort" => sort_pipeline }

      aggregation = model.collection.aggregate(pipes)
      aggregation.each do |data|
        parse_data(data)
      end
      @prefs
    end

    private

    def group_pipeline
      {
        _id: {
          site_id: "$site_id",
          result_closed: "$result_closed",

          # user
          user_id: "$target_user_id",
          user_code: "$target_user_code",
          user_staff_address_uid: "$target_user_staff_address_uid",

          # group
          group_id: "$target_group_id",

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
    end

    def sort_pipeline
      { "_id.date" => 1 }
    end

    def threshold
      @threshold ||= SS.config.gws.affair.dig("overtime", "aggregate", "threshold_hour") * 60
    end

    def unclosed?(data)
      result_closed = data["_id"]["result_closed"]
      file_id = data["_id"]["file_id"]

      return false if @unclosed_file_ids.include?(file_id)
      return result_closed.blank?
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def parse_data(data)
      # 結果が確定していない為、集計対象外
      return if unclosed?(data)

      site_id = data["_id"]["site_id"]
      user_id = data["_id"]["user_id"]
      user_code = data["_id"]["user_code"]
      user_staff_address_uid = data["_id"]["user_staff_address_uid"]
      group_id = data["_id"]["group_id"]
      date = data["_id"]["date"]
      fiscal_year = data["_id"]["fiscal_year"]
      month = data["_id"]["month"]
      start_at = data["_id"]["start_at"]
      end_at = data["_id"]["end_at"]
      capital_code = data["_id"]["capital_code"]
      project_code = data["_id"]["project_code"]
      detail_code = data["_id"]["detail_code"]
      file_id = data["_id"]["file_id"]

      duty_day_time_minute = data["duty_day_time_minute"]
      duty_day_in_work_time_minute = data["duty_day_in_work_time_minute"]
      duty_night_time_minute = data["duty_night_time_minute"]

      leave_day_time_minute = data["leave_day_time_minute"]
      leave_night_time_minute = data["leave_night_time_minute"]

      week_in_compensatory_minute = data["week_in_compensatory_minute"]
      holiday_compensatory_minute = data["holiday_compensatory_minute"]
      break_time_minute = data["break_time_minute"]

      unrate_week_out_compensatory_minute = data["week_out_compensatory_minute"]
      week_out_compensatory_minute = 0

      # 週内、週外残業（土日）があった場合、休出区分割増にならない
      if week_in_compensatory_minute > 0 || unrate_week_out_compensatory_minute > 0
        duty_day_time_minute += leave_day_time_minute
        duty_night_time_minute += leave_night_time_minute

        leave_day_time_minute = 0
        leave_night_time_minute = 0
      end

      # 週外残業は、その週の業務時間合計が 38.75h (2325m) を超えない場合、割増がつかない
      week_working = nil
      if unrate_week_out_compensatory_minute > 0
        @week_working_extractor.week_at(site_id, user_id, date.to_date)
        week_working = @week_working_extractor.week_working
        week_working_minute = @week_working_extractor.week_minutes

        if week_working_minute >= 2325
          unrate_week_out_compensatory_minute = 0
          week_out_compensatory_minute = data["week_out_compensatory_minute"]
        end
      end

      @subtractors[user_id] ||= Gws::Affair::Subtractor.new(threshold)
      w_c_m = week_out_compensatory_minute # 0. 025/100
      i_w_m = duty_day_in_work_time_minute # 1. 100/100
      d_d_m = duty_day_time_minute         # 2. 125/100
      l_d_m = leave_day_time_minute        # 3. 135/100
      d_n_m = duty_night_time_minute       # 4. 150/100
      l_n_m = leave_night_time_minute      # 5. 160/100

      under_minutes, over_minutes = @subtractors[user_id].subtract(w_c_m, i_w_m, d_d_m, l_d_m, d_n_m, l_n_m)

      under_overtime_minute = under_minutes.sum
      over_overtime_minute = over_minutes.sum
      overtime_minute = under_overtime_minute + over_overtime_minute

      @prefs[user_id] ||= {}
      @prefs[user_id][file_id] = {
        # user
        user_id: user_id,
        user_code: user_code,
        user_staff_address_uid: user_staff_address_uid,

        # group
        group_id: group_id,

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
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
