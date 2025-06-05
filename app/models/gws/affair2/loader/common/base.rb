class Gws::Affair2::Loader::Common::Base
  include ActiveModel::Model

  attr_accessor :site

  delegate :time_range_minutes, to: Gws::Affair2::Utils

  def night_time_start_at(date)
    site.affair2_night_time_start_at(date)
  end

  def night_time_close_at(date)
    site.affair2_night_time_close_at(date)
  end

  # 1日465mを超えたら割増時間外として扱う。それ以下は時短。
  def daily_threshold
    SS.config.affair2.overtime["daily_threshold"]
  end

  # 月30hを超えると割増率が変わる
  def monthly_threshold
    SS.config.affair2.overtime["monthly_threshold"]
  end

  def monthly_threshold_hour
    monthly_threshold / 60
  end

  ## set methods
  def set_basic(item, date, record)
    item.date = date
    item.enter = record.enter
    item.leave = record.leave
    item.regular_start = record.regular_start
    item.regular_close = record.regular_close
    item.break_minutes = record.break_minutes.to_i
  end

  # leave_minutes_hash
  # leave_minutes
  def set_leave_minutes(item, date, record, leave_records:)
    item.leave_minutes_hash = {}
    item.leave_minutes = 0

    return if leave_records.blank?
    leave_records.each do |r|
      item.leave_minutes_hash[r.leave_type] ||= 0
      item.leave_minutes_hash[r.leave_type] += r.minutes
      item.leave_minutes += r.minutes
    end
  end

  # work_minutes1
  # work_minutes2
  # work_overtime_minutes
  def set_work_minutes(item, date, record, leave_records:)
    item.work_minutes1 = record.work_minutes.to_i
    item.work_overtime_minutes = record.over_minutes.to_i

    if !record.entered? || record.regular_holiday?
      item.work_minutes2 = 0
      return
    end

    # 勤務時間 から 休暇時間を引いた区分を算出
    main_range = (record.effective_enter..record.effective_leave)
    sub_ranges = leave_records.map { |r| (r.start_at..r.close_at) }

    minutes = ::Gws::Affair2::Utils.time_range_minutes(main_range, *sub_ranges)
    item.work_minutes2 = minutes[0] - record.break_minutes
    item.work_minutes2 = 0 if item.work_minutes2 < 0
  end

  #overtime_minutes
  #overtime_short_minutes
  #overtime_day_minutes
  #overtime_night_minutes
  def set_overtime_minutes(item, date, record, overtime_records:)
    enter = record.enter
    leave = record.leave
    regular_start = record.regular_start
    regular_close = record.regular_close
    break_minutes = record.break_minutes.to_i

    overtime_records = overtime_records.select { |r| r.entered? && !r.holiday? }

    item.overtime_minutes = 0
    if overtime_records.blank?
      item.overtime_short_minutes = 0
      item.overtime_day_minutes = 0
      item.overtime_night_minutes = 0
      return
    end

    # 通常残業の場合は 所定終業 から 深夜時間外終了 まで
    day_range = (record.regular_close..night_time_start_at(date))
    night_range = (night_time_start_at(date)..night_time_close_at(date))

    sub_ranges = []
    sub_ranges += overtime_records.map { |r| (r.start_at..r.close_at) }
    sub_ranges += overtime_records.map { |r| (r.break_start_at..r.break_close_at) }

    day_minutes = ::Gws::Affair2::Utils.time_range_minutes(day_range, *sub_ranges)
    day_minutes = day_minutes[(1..overtime_records.size)].sum

    night_minutes = ::Gws::Affair2::Utils.time_range_minutes(night_range, *sub_ranges)
    night_minutes = night_minutes[(1..overtime_records.size)].sum

    # 時短
    cup = Gws::Affair2::Loader::Common::Cup.new(daily_threshold - item.work_minutes2)
    day_minutes = cup.pour(day_minutes)
    night_minutes = cup.pour(night_minutes)
    short_minutes = cup.pool

    item.overtime_short_minutes = short_minutes
    item.overtime_day_minutes = day_minutes
    item.overtime_night_minutes = night_minutes
    item.overtime_minutes += short_minutes + day_minutes + night_minutes
  end

  # compens_overtime_day_minutes
  # compens_overtime_night_minutes
  def set_compens_overtime_minutes(item, date, record, overtime_records:)
    overtime_records = overtime_records.select { |r| r.entered? && r.holiday? && r.compens? }

    if overtime_records.blank?
      item.compens_overtime_day_minutes = 0
      item.compens_overtime_night_minutes = 0
      return
    end

    # 休業日残業の場合は 前日の深夜時間外終了 から 深夜時間外終了 まで
    day_range = (night_time_close_at(date.advance(days: -1))..night_time_start_at(date))
    night_range = (night_time_start_at(date)..night_time_close_at(date))

    sub_ranges = []
    sub_ranges += overtime_records.map { |r| (r.start_at..r.close_at) }
    sub_ranges += overtime_records.map { |r| (r.break_start_at..r.break_close_at) }

    day_minutes = ::Gws::Affair2::Utils.time_range_minutes(day_range, *sub_ranges)
    day_minutes = day_minutes[(1..overtime_records.size)].sum

    night_minutes = ::Gws::Affair2::Utils.time_range_minutes(night_range, *sub_ranges)
    night_minutes = night_minutes[(1..overtime_records.size)].sum

    item.compens_overtime_day_minutes = day_minutes
    item.compens_overtime_night_minutes = night_minutes
    item.overtime_minutes += day_minutes + night_minutes
  end

  # settle_overtime_day_minutes
  # settle_overtime_night_minutes
  def set_settle_overtime_minutes(item, date, user, overtime_records:)
    overtime_records = overtime_records.select { |r| r.entered? && r.holiday? && r.settle? }

    if overtime_records.blank?
      item.settle_overtime_day_minutes = 0
      item.settle_overtime_night_minutes = 0
      return
    end

    # 休業日残業の場合は 前日の深夜時間外終了 から 深夜時間外終了 まで
    day_range = (night_time_close_at(date.advance(days: -1))..night_time_start_at(date))
    night_range = (night_time_start_at(date)..night_time_close_at(date))

    sub_ranges = []
    sub_ranges += overtime_records.map { |r| (r.start_at..r.close_at) }
    sub_ranges += overtime_records.map { |r| (r.break_start_at..r.break_close_at) }

    day_minutes = ::Gws::Affair2::Utils.time_range_minutes(day_range, *sub_ranges)
    day_minutes = day_minutes[(1..overtime_records.size)].sum

    night_minutes = ::Gws::Affair2::Utils.time_range_minutes(night_range, *sub_ranges)
    night_minutes = night_minutes[(1..overtime_records.size)].sum

    item.settle_overtime_day_minutes = day_minutes
    item.settle_overtime_night_minutes = night_minutes
    item.overtime_minutes += day_minutes + night_minutes
  end
end
