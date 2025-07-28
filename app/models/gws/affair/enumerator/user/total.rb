class Gws::Affair::Enumerator::User::Total < Gws::Affair::Enumerator::Base
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
    line << I18n.t("gws/affair.labels.overtime.total.under")
    line << I18n.t("gws/affair.labels.overtime.total.over")
    line << I18n.t("gws/affair.labels.overtime.total.sum")
    line
  end

  private

  def set_record(yielder, user)
    total_under_minutes = @prefs.dig(user.id, @capital_basic_code, "under_threshold", "overtime_minute").to_i
    total_over_minutes = @prefs.dig(user.id, @capital_basic_code, "over_threshold", "overtime_minute").to_i
    overtime_minute = total_under_minutes + total_over_minutes

    line = []
    line << user.long_name
    line << user.organization_uid
    line << format_minute(total_under_minutes)
    line << format_minute(total_over_minutes)
    line << format_minute(overtime_minute)
    yielder << encode(line.to_csv)
  end
end
