class Gws::Affair2::Book::PaidLeave < Gws::Affair2::Book::Leave::Base
  include Gws::SitePermission

  set_permission_name "gws_affair2_paid_leave_books"

  validate :validate_paid_leave_setting

  def title
    I18n.t("gws/affair2.book.leave.paid_title", year: year)
  end

  def carryover_minutes_label
    return if carryover_minutes.nil?
    format_minutes(carryover_minutes)
  end

  def additional_minutes_label
    return if additional_minutes.nil?
    format_minutes(additional_minutes)
  end

  def effective_minutes_label
    return if effective_minutes.nil?
    format_minutes(effective_minutes)
  end

  def remind_minutes_label
    return if remind_minutes.nil?
    format_minutes(remind_minutes)
  end

  def load(site, user, year, group)
    @site = site
    @user = user
    @year = year
    @group = group

    @start_date = Time.zone.local(year, 1, 1)
    @close_date = @start_date.end_of_year

    @tables = []
    @tables << 7.times.map { Gws::Affair2::Book::Leave::Column.new }

    set_paid_leave_setting
    return if invalid?

    @carryover_minutes = paid_leave_setting.carryover_minutes
    @additional_minutes = paid_leave_setting.additional_minutes
    @effective_minutes = @carryover_minutes + @additional_minutes
    @used_minutes = 0
    @remind_minutes = 0

    @leave_files = Gws::Affair2::Leave::File.site(site).user(user).and([
      start_at: { "$gte" => start_date },
      close_at: { "$lte" => close_date },
      workflow_state: "approve"
    ]).order_by(start_at: 1).to_a
    @leave_files = @leave_files.select { |item| item.paid_leave? }

    @tables = []

    if @leave_files.size == 0
      size = 7
    else
      size = (@leave_files.size / 7) * 7
      size += 7 if (@leave_files.size % 7) != 0
    end
    (size).times.each do |i|
      page = i / 7
      @tables[page] ||= []

      file = @leave_files[i]
      column = Gws::Affair2::Book::Leave::Column.new
      column.file = file

      if file && file.records.present?
        @used_minutes += file.records.map(&:minutes).sum
        column.used_minutes = @used_minutes
        column.day_leave_minutes = @duty_setting.day_leave_minutes
      end

      @tables[page] << column
    end
    @remind_minutes = @effective_minutes - @used_minutes
  end

  private

  def set_paid_leave_setting
    # 対象年の最新の出退勤設定を参照する
    @attendance_setting = Gws::Affair2::AttendanceSetting.site(@site).user(@user).
      and_between(start_date, close_date).first
    return if @attendance_setting.nil?

    @duty_setting = @attendance_setting.duty_setting
    @paid_leave_setting = @attendance_setting.paid_leave_settings.where(year: year).first
  end

  def validate_paid_leave_setting
    if @attendance_setting.nil? || @duty_setting.nil? || @paid_leave_setting.nil?
      errors.add :base, I18n.t("gws/affair2.book.leave.errors.no_paid_leave_setting")
    end
  end
end
