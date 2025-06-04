class Gws::Affair2::Leave::RecordValidator
  attr_reader :file, :user, :site
  attr_reader :allday, :start_at, :close_at, :year
  attr_reader :attendance_setting, :duty_setting
  attr_reader :time_cards, :time_card_records
  attr_reader :total_leave_minutes, :records

  delegate :errors, to: :file
  delegate :day_leave_minutes, to: :duty_setting
  delegate :time_to_min, :min_to_time, to: Gws::Affair2::Utils

  def initialize(file)
    @file = file
    @site = file.site
    @user = file.user
    @allday = file.allday
    @start_at = file.start_at
    @close_at = file.close_at
  end

  def validate
    validate_start_close
    validate_year
    validate_attendance_setting
    validate_duty_setting
    validate_time_card
    validate_records
    validate_paid_leave
  end

  def validate_start_close
    errors.add :start_at, :blank if start_at.nil?
    errors.add :close_at, :blank if close_at.nil?
    if start_at && close_at && start_at >= close_at
      errors.add :close_at, :after_than, time: file.t(:start_at)
    end
  end

  # 年跨ぎの申請は不可
  def validate_year
    return if errors.present?

    if start_at.year != close_at.year
      errors.add :base, "開始日〜終了日を同一年にしてください。"
    end
    @year = start_at.year
  end

  # 開始日と終了時で出勤簿設定があり、かつ同じ出勤簿設定
  def validate_attendance_setting
    return if errors.present?

    start_attendance = Gws::Affair2::AttendanceSetting.current_setting(site, user, start_at)
    close_attendance = Gws::Affair2::AttendanceSetting.current_setting(site, user, close_at)
    if start_attendance.nil? || close_attendance.nil?
      errors.add :base, "開始日〜終了日にて出勤簿設定がありません。"
    elsif start_attendance.id != close_attendance.id
      errors.add :base, "開始日〜終了日にて異なる出勤簿設定があります。"
    end
    @attendance_setting = start_attendance
  end

  # 出勤簿設定に雇用区分が正しく設定されているか
  def validate_duty_setting
    return if errors.present?

    @duty_setting = @attendance_setting.duty_setting
    if duty_setting.nil?
      errors.add :base, "開始日〜終了日にて出勤簿設定が不正です。"
    end
  end

  # 対象日のタイムカードが作成されているか
  # - 対象日が勤務日か
  # - 対象日の所定開始、所定終了（時短区分算出の為）
  def validate_time_card
    return if errors.present?

    dates = (start_at.to_date..close_at.to_date).to_a
    months = dates.map { |date| [date.year, date.month] }.uniq
    months = months.map { |year, month| Time.zone.local(year, month, 1) }
    @time_cards = Gws::Affair2::Attendance::TimeCard.site(site).user(user).in(date: months).to_a

    months.each do |month|
      item = @time_cards.find { |item| item.date == month }
      if item.nil?
        errors.add :base, "タイムカードが作成されていません。(#{month.year}年#{month.month}月)"
        next
      end
      if !item.regular_open?
        errors.add :base, "タイムカードの所定時間が設定されていません。(#{month.year}年#{month.month}月)"
      end
    end
    @time_card_records = @time_cards.map(&:records).flatten.index_by(&:date)
  end

  # 各日チェック
  def validate_records
    return if errors.present?

    @records = []
    @total_leave_minutes = 0

    if allday == "allday"
      # 終日
      (start_at.to_date..close_at.to_date).each do |date|
        trecord = time_card_records[date.in_time_zone.to_datetime]
        if trecord.regular_workday?
          record = new_record
          record.date = date
          record.allday = "allday"
          record.start_at = trecord.regular_start
          record.close_at = trecord.regular_close
          record.minutes = trecord.regular_work_minutes
          record.day_leave_minutes = day_leave_minutes

          @records << record
          @total_leave_minutes += record.minutes
        end
      end
    else
      # 時間休
      date = start_at.to_date
      trecord = time_card_records[date.in_time_zone.to_datetime]
      if trecord.regular_workday?
        record = new_record
        record.date = date
        #
        record.start_at = (start_at > trecord.regular_start) ? start_at : trecord.regular_start
        record.close_at = (close_at < trecord.regular_close) ? close_at : trecord.regular_close
        #
        record.minutes = time_to_min(record.close_at, date: record.date) - time_to_min(record.start_at, date: record.date)
        record.minutes = day_leave_minutes if record.minutes > day_leave_minutes
        record.day_leave_minutes = day_leave_minutes

        @records << record
        @total_leave_minutes += record.minutes
      end
    end
    errors.add :base, "開始日〜終了日が休業日です。" if @records.blank?
  end

  # 年次有給
  def validate_paid_leave
    return if errors.present?
    return if !file.paid_leave?

    paid_leave_setting = attendance_setting.paid_leave_settings.where(year: year).first
    if paid_leave_setting.nil?
      errors.add :base, "有給休暇日数が設定されていません。"
      return
    end

    paid_leave_setting.without_file_id = file.id
    if (paid_leave_setting.remind_minutes - total_leave_minutes) < 0
      label = paid_leave_setting.leave_minutes_label(total_leave_minutes, day_leave_minutes)
      errors.add :base, "年次有給休暇の有効時間が足りません。(取得時間：#{label})"
    end
  end

  def new_record
    record = Gws::Affair2::Leave::Record.new
    record.cur_site = site
    record.cur_user = user
    record.leave_type = file.leave_type
    if file.state == Workflow::Approver::WORKFLOW_STATE_APPROVE
      record.state = "order"
    else
      record.state = "request"
    end
    record
  end
end
