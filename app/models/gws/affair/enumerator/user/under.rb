class Gws::Affair::Enumerator::User::Under < Gws::Affair::Enumerator::Base
  def initialize(prefs, users, opts = {})
    @prefs = prefs
    @users = users

    @title = opts[:title]
    @encoding = opts[:encoding]
    @capital_basic_code = opts[:capital_basic_code].presence || "total"

    super() do |y|
      set_title_and_headers(y)
      @users.each do |user|
        set_record(y, user)
      end
    end
  end

  def headers
    line = []
    line << Gws::User.t(:name)
    line << Gws::User.t(:organization_uid)
    line << I18n.t("gws/affair.labels.overtime.under_threshold.duty_day_time.rate")
    line << I18n.t("gws/affair.labels.overtime.under_threshold.duty_night_time.rate")
    line << I18n.t("gws/affair.labels.overtime.under_threshold.duty_day_in_work_time.rate")
    line << I18n.t("gws/affair.labels.overtime.under_threshold.leave_day_time.rate")
    line << I18n.t("gws/affair.labels.overtime.under_threshold.leave_night_time.rate")
    line << I18n.t("gws/affair.labels.overtime.under_threshold.week_out_compensatory.rate")
    line
  end

  private

  def set_record(yielder, user)
    duty_day_time_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "duty_day_time_minute")
    duty_night_time_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "duty_night_time_minute")
    duty_day_in_work_time_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "duty_day_in_work_time_minute")
    leave_day_time_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "leave_day_time_minute")
    leave_night_time_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "leave_night_time_minute")
    week_out_compensatory_minute = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "week_out_compensatory_minute")

    line = []
    line << user.long_name
    line << user.organization_uid
    line << format_minute(duty_day_time_minute)
    line << format_minute(duty_night_time_minute)
    line << format_minute(duty_day_in_work_time_minute)
    line << format_minute(leave_day_time_minute)
    line << format_minute(leave_night_time_minute)
    line << format_minute(week_out_compensatory_minute)
    yielder << encode(line.to_csv)
  end
end
