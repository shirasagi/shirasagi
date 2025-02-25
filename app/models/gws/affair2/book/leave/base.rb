class Gws::Affair2::Book::Leave::Base
  include ActiveModel::Model

  attr_reader :site, :user, :year, :group
  attr_reader :start_date, :close_date
  attr_reader :attendance_setting, :duty_setting, :paid_leave_setting
  attr_reader :tables, :leave_files
  attr_reader :carryover_minutes, :additional_minutes, :effective_minutes, :remind_minutes

  def title
    raise "not implemented"
  end

  def user_name
    user.name
  end

  def user_title
    user.titles.first.try(:name)
  end

  def group_name
    group.try(:trailing_name)
  end

  def day_leave_minutes
    duty_setting.day_leave_minutes
  end

  def load
    raise "not implemented"
  end

  private

  def format_minutes(minutes)
    days = minutes / day_leave_minutes
    rem_minutes = minutes % day_leave_minutes

    rem_hours = rem_minutes / 60
    rem_minutes = rem_minutes % 60
    "#{days}日#{rem_hours}時#{rem_minutes}分"
  end
end
