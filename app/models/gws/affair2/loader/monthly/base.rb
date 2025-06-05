class Gws::Affair2::Loader::Monthly::Base < Gws::Affair2::Loader::Common::Base
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength

  attr_accessor :user, :time_card, :notice_messages,
    :time_card_records, :overtime_records, :leave_records, :load_records,
    :work_minutes1, :work_minutes2,
    # overtime total
    :overtime_minutes, :overtime_minutes1, :overtime_minutes2,
    # short, day, night
    :overtime_short_minutes1, :overtime_day_minutes1, :overtime_night_minutes1,
    :overtime_short_minutes2, :overtime_day_minutes2, :overtime_night_minutes2,
    # compens
    :compens_overtime_day_minutes1, :compens_overtime_night_minutes1,
    :compens_overtime_day_minutes2, :compens_overtime_night_minutes2,
    # settle
    :settle_overtime_day_minutes1, :settle_overtime_night_minutes1,
    :settle_overtime_day_minutes2, :settle_overtime_night_minutes2,
    # leave
    :leave_minutes, :leave_minutes_hash

  def initialize(time_card)
    @time_card = time_card

    if time_card
      @site = time_card.site
      @user = time_card.user
    end

    @time_card_records = {}
    @overtime_records = {}
    @leave_records = {}
    @load_records = {}
    @notice_messages = []
  end

  def month
    time_card.date
  end

  def load
    return if time_card.nil?

    set_time_card_records
    set_overtime_records
    set_leave_records

    if time_card.regular_open?
      @load_records = {}
      time_card_records.each do |date, record|
        item = OpenStruct.new
        set_basic(item, date, record)

        records = @leave_records[date].to_a
        set_leave_minutes(item, date, record, leave_records: records)
        set_work_minutes(item, date, record, leave_records: records)

        records = @overtime_records[date].to_a
        set_overtime_minutes(item, date, record, overtime_records: records)
        set_compens_overtime_minutes(item, date, record, overtime_records: records)
        set_settle_overtime_minutes(item, date, record, overtime_records: records)

        @load_records[date] = item
      end
      sum_leave_minutes
      sum_work_minutes
      sum_overtime_minutes
    end
    set_notice_messages
  end

  def set_time_card_records
    @time_card_records = {}
    time_card.records.each do |item|
      @time_card_records[item.date] = item
    end
  end

  def set_overtime_records
    @overtime_records = {}
    items = Gws::Affair2::Overtime::Record.site(site).and(
      { "user_id" => time_card.user_id },
      { "state" => { "$ne" => "request" } },
      { "$and" => [
        { "date" => { "$gte" => month } },
        { "date" => { "$lte" => month.end_of_month } }
      ]})
    items.each do |item|
      date = item.date.in_time_zone.to_datetime
      @overtime_records[date] ||= []
      @overtime_records[date] << item
    end
  end

  def set_leave_records
    @leave_records = {}
    items = Gws::Affair2::Leave::Record.site(site).and(
      { "user_id" => time_card.user_id },
      { "state" => { "$ne" => "request" } },
      { "$and" => [
        { "date" => { "$gte" => month } },
        { "date" => { "$lte" => month.end_of_month } }
      ]})
    items.each do |item|
      date = item.date.in_time_zone.to_datetime
      @leave_records[date] ||= []
      @leave_records[date] << item
    end
  end

  def set_notice_messages
    return if time_card.nil?

    @notice_messages = []
    if !time_card.regular_open?
      @notice_messages << I18n.t("gws/affair2.time_card_errors.regular_open")
    end
    if time_card.attendance_setting.nil?
      @notice_messages << I18n.t("gws/affair2.time_card_errors.no_attendance_setting")
    end
    return if @notice_messages.present?

    duty_notices = time_card.attendance_setting.duty_setting.duty_notices.to_a rescue []
    return if duty_notices.blank?

    duty_notices.each do |duty_notice|
      case duty_notice.notice_type
      when "monthly_overtime_limit"
        if overtime_minutes > duty_notice.threshold_hour * 60
          @notice_messages << duty_notice.body
        end
      end
    end
  end

  def sum_leave_minutes
    @leave_minutes_hash = {}
    @leave_minutes = 0

    @load_records.each do |date, item|
      item.leave_minutes_hash.each do |leave_type, minutes|
        @leave_minutes_hash[leave_type] ||= 0
        @leave_minutes_hash[leave_type] += minutes
        @leave_minutes += minutes
      end
    end
  end

  def sum_work_minutes
    @work_minutes1 = 0
    @work_minutes2 = 0

    @load_records.each do |date, item|
      @work_minutes1 += item.work_minutes1
      @work_minutes2 += item.work_minutes2
    end
  end

  def sum_overtime_minutes
    subtractor = Gws::Affair::Subtractor.new(monthly_threshold)

    # 30h未満
    @overtime_short_minutes1 = 0
    @overtime_day_minutes1 = 0
    @overtime_night_minutes1 = 0
    @compens_overtime_day_minutes1 = 0
    @compens_overtime_night_minutes1 = 0
    @settle_overtime_day_minutes1 = 0
    @settle_overtime_night_minutes1 = 0
    # 30h未満合計
    @overtime_minutes1 = 0

    # 30h以上
    @overtime_short_minutes2 = 0
    @overtime_day_minutes2 = 0
    @overtime_night_minutes2 = 0
    @compens_overtime_day_minutes2 = 0
    @compens_overtime_night_minutes2 = 0
    @settle_overtime_day_minutes2 = 0
    @settle_overtime_night_minutes2 = 0
    # 30h以上合計
    @overtime_minutes2 = 0

    @load_records.each do |date, item|
      s_m = item.overtime_short_minutes
      d_m = item.overtime_day_minutes
      n_m = item.overtime_night_minutes

      cd_m = item.compens_overtime_day_minutes
      cn_m = item.compens_overtime_night_minutes

      sd_m = item.settle_overtime_day_minutes
      sn_m = item.settle_overtime_night_minutes

      normal_minutes, extra_minutes = subtractor.subtract(s_m, d_m, n_m, cd_m, cn_m, sd_m, sn_m)

      item.overtime_short_minutes1         = normal_minutes[0]
      item.overtime_day_minutes1           = normal_minutes[1]
      item.overtime_night_minutes1         = normal_minutes[2]
      item.compens_overtime_day_minutes1   = normal_minutes[3]
      item.compens_overtime_night_minutes1 = normal_minutes[4]
      item.settle_overtime_day_minutes1    = normal_minutes[5]
      item.settle_overtime_night_minutes1  = normal_minutes[6]
      item.over_minutes1                   = normal_minutes.sum

      item.overtime_short_minutes2         = extra_minutes[0]
      item.overtime_day_minutes2           = extra_minutes[1]
      item.overtime_night_minutes2         = extra_minutes[2]
      item.compens_overtime_day_minutes2   = extra_minutes[3]
      item.compens_overtime_night_minutes2 = extra_minutes[4]
      item.settle_overtime_day_minutes2    = extra_minutes[5]
      item.settle_overtime_night_minutes2  = extra_minutes[6]
      item.over_minutes2                   = extra_minutes.sum

      @overtime_short_minutes1 += item.overtime_short_minutes1
      @overtime_day_minutes1 += item.overtime_day_minutes1
      @overtime_night_minutes1 += item.overtime_night_minutes1
      @compens_overtime_day_minutes1 += item.compens_overtime_day_minutes1
      @compens_overtime_night_minutes1 += item.compens_overtime_night_minutes1
      @settle_overtime_day_minutes1 += item.settle_overtime_day_minutes1
      @settle_overtime_night_minutes1 += item.settle_overtime_night_minutes1

      @overtime_short_minutes2 += item.overtime_short_minutes2
      @overtime_day_minutes2 += item.overtime_day_minutes2
      @overtime_night_minutes2 += item.overtime_night_minutes2
      @compens_overtime_day_minutes2 += item.compens_overtime_day_minutes2
      @compens_overtime_night_minutes2 += item.compens_overtime_night_minutes2
      @settle_overtime_day_minutes2 += item.settle_overtime_day_minutes2
      @settle_overtime_night_minutes2 += item.settle_overtime_night_minutes2

      @overtime_minutes1 += item.over_minutes1
      @overtime_minutes2 += item.over_minutes2
    end
    @overtime_minutes = @overtime_minutes1 + @overtime_minutes2
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
end
