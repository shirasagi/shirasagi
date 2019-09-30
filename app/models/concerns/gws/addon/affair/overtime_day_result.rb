module Gws::Addon::Affair::OvertimeDayResult
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    has_many :day_results, class_name: 'Gws::Affair::OvertimeDayResult', dependent: :destroy, inverse_of: :file
    after_save :save_day_results
  end

  def aggregate_day_results
    Gws::Affair::OvertimeDayResult.site(site).where(
      date_year: date.year,
      date_month: date.month,
      target_user_id: target_user_id,
      target_user_code: target_user_code
    ).aggregate_partition(unclosed_file_ids: [self.id])
  end

  def save_day_results
    return if result.blank?
    return if result_closed?

    # 申請対象の勤務カレンダー、勤務体系
    duty_calendar = target_user.effective_duty_calendar(site)
    duty_hour = duty_calendar.effective_duty_hour(result.date)

    # 振替時間
    week_in_subtractor = Gws::Affair::Subtractor.new(week_in_compensatory_minute)
    week_out_subtractor = Gws::Affair::Subtractor.new(week_out_compensatory_minute)
    holiday_compensatory_subtractor = Gws::Affair::Subtractor.new(holiday_compensatory_minute)

    # 100/100 残業（標準勤務時間）
    default_duty_hour = Gws::Affair::DefaultDutyHour.new(cur_site: site)

    # 結果を全削除
    day_results.destroy_all

    # 休憩 開始 終了
    if result.break1_start_at && result.break1_end_at
      break1_start_at = result.break1_start_at
      break1_end_at = result.break1_end_at
    else
      break1_start_at = result.start_at
      break1_end_at = result.start_at
    end

    if result.break2_start_at && result.break2_end_at
      break2_start_at = result.break2_start_at
      break2_end_at = result.break2_end_at
    else
      break2_start_at = result.start_at
      break2_end_at = result.start_at
    end

    # 深夜 開始 終了
    night_time_start = duty_calendar.night_time_start(result.date.to_datetime).to_datetime
    night_time_end = duty_calendar.night_time_end(result.date.to_datetime).to_datetime

    if duty_hour.overtime_in_work?
      # 通常 時短 深夜 休憩時間
      default_affair_start = default_duty_hour.affair_start(result.date)
      default_affair_end = default_duty_hour.affair_end(result.date)
      day_time_minute, day_in_work_time_minute, night_time_minute, break1_time_minute, break2_time_minute = Gws::Affair::Utils.time_range_minutes(
        (result.start_at..result.end_at),
        (default_affair_start..default_affair_end),
        (night_time_start..night_time_end),
        (break1_start_at..break1_end_at),
        (break2_start_at..break2_end_at)
      )
      break_time_minute = break1_time_minute + break2_time_minute
    else
      # 通常 深夜 休憩時間
      day_time_minute, night_time_minute, break1_time_minute, break2_time_minute = Gws::Affair::Utils.time_range_minutes(
        (result.start_at..result.end_at),
        (night_time_start..night_time_end),
        (break1_start_at..break1_end_at),
        (break2_start_at..break2_end_at)
      )
      break_time_minute = break1_time_minute + break2_time_minute
      day_in_work_time_minute = 0
    end

    # 休日通常 休日深夜
    is_holiday = duty_calendar.leave_day?(result.date)
    if is_holiday
      duty_day_time_minute = 0
      duty_day_in_work_time_minute = 0
      duty_night_time_minute = 0

      leave_day_time_minute = day_time_minute + day_in_work_time_minute
      leave_night_time_minute = night_time_minute
    else
      duty_day_time_minute = day_time_minute
      duty_day_in_work_time_minute = day_in_work_time_minute
      duty_night_time_minute = night_time_minute

      leave_day_time_minute = 0
      leave_night_time_minute = 0
    end

    # 振替時間（週内）
    if week_in_subtractor.threshold > 0
      threshold = week_in_subtractor.threshold

      _, subtracted = week_in_subtractor.subtract(
        duty_day_in_work_time_minute,
        duty_day_time_minute,
        duty_night_time_minute,
        leave_day_time_minute,
        leave_night_time_minute
      )
      duty_day_in_work_time_minute = subtracted[0]
      duty_day_time_minute = subtracted[1]
      duty_night_time_minute = subtracted[2]
      leave_day_time_minute = subtracted[3]
      leave_night_time_minute = subtracted[4]

      week_in_compensatory_minute = threshold - week_in_subtractor.threshold
    else
      week_in_compensatory_minute = 0
    end

    # 振替時間（週外）
    if week_out_subtractor.threshold > 0
      threshold = week_out_subtractor.threshold

      _, subtracted = week_out_subtractor.subtract(
        duty_day_in_work_time_minute,
        duty_day_time_minute,
        duty_night_time_minute,
        leave_day_time_minute,
        leave_night_time_minute
      )
      duty_day_in_work_time_minute = subtracted[0]
      duty_day_time_minute = subtracted[1]
      duty_night_time_minute = subtracted[2]
      leave_day_time_minute = subtracted[3]
      leave_night_time_minute = subtracted[4]

      week_out_compensatory_minute = threshold - week_out_subtractor.threshold
    else
      week_out_compensatory_minute = 0
    end

    # 振替時間（代休）
    if holiday_compensatory_subtractor.threshold > 0
      threshold = holiday_compensatory_subtractor.threshold

      _, subtracted = holiday_compensatory_subtractor.subtract(
        duty_day_in_work_time_minute,
        duty_day_time_minute,
        duty_night_time_minute,
        leave_day_time_minute,
        leave_night_time_minute
      )
      duty_day_in_work_time_minute = subtracted[0]
      duty_day_time_minute = subtracted[1]
      duty_night_time_minute = subtracted[2]
      leave_day_time_minute = subtracted[3]
      leave_night_time_minute = subtracted[4]

      holiday_compensatory_minute = threshold - holiday_compensatory_subtractor.threshold
    else
      holiday_compensatory_minute = 0
    end

    cond = {
      site_id: site.id,
      user_id: user.id,
      date: result.date,
      file_id: id
    }
    item = Gws::Affair::OvertimeDayResult.find_or_initialize_by(cond)
    item.file = self
    item.cur_user = user
    item.cur_site = site
    item.date_year = result.date.year
    item.date_month = result.date.month
    item.date_fiscal_year = (item.date_month >= site.attendance_year_changed_month) ? item.date_year : item.date_year - 1

    item.start_at = result.start_at
    item.end_at = result.end_at
    item.capital_id = capital_id

    item.is_holiday = is_holiday
    item.duty_day_time_minute = duty_day_time_minute
    item.duty_night_time_minute = duty_night_time_minute
    item.leave_day_time_minute = leave_day_time_minute
    item.leave_night_time_minute = leave_night_time_minute

    item.break1_start_at = result.break1_start_at
    item.break1_end_at = result.break1_end_at
    item.break2_start_at = result.break2_start_at
    item.break2_end_at = result.break2_end_at
    item.break_time_minute = break_time_minute

    item.week_in_compensatory_minute = week_in_compensatory_minute
    item.week_out_compensatory_minute = week_out_compensatory_minute
    item.holiday_compensatory_minute = holiday_compensatory_minute

    item.duty_day_in_work_time_minute = duty_day_in_work_time_minute

    item.save
  end
end
