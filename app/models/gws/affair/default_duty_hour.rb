class Gws::Affair::DefaultDutyHour
  include ActiveModel::Model
  include Gws::SitePermission

  set_permission_name "gws_affair_duty_hours"

  attr_accessor :cur_site

  def new_record?
    false
  end

  def persisted?
    true
  end

  def destroyed?
    false
  end

  def id
    "default"
  end

  def name
    I18n.t("gws/affair.default_duty_hour")
  end

  def addons
    []
  end

  def lookup_addons
  end

  def method_missing(name, *args, &block)
    if cur_site.respond_to?(name)
      return cur_site.send(name, *args, &block)
    end

    super
  end

  def respond_to_missing?(name, include_private)
    return true if cur_site.respond_to?(name, include_private)

    super
  end

  def affair_start(time)
    time.change(hour: affair_start_at_hour, min: affair_start_at_minute, sec: 0)
  end

  def affair_end(time)
    time.change(hour: affair_end_at_hour, min: affair_end_at_minute, sec: 0)
  end

  def affair_break_start(time)
    time.change(hour: affair_break_start_at_hour, min: affair_break_start_at_minute, sec: 0)
  end

  def affair_break_end(time)
    time.change(hour: affair_break_end_at_hour, min: affair_break_end_at_minute, sec: 0)
  end

  def affair_next_changed(time)
    hour = attendance_time_changed_minute / 60
    changed = time.change(hour: hour, min: 0, sec: 0)
    (time > changed) ? changed.advance(days: 1) : changed
  end

  def night_time_start(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "start_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
  end

  def night_time_end(time)
    hour = SS.config.gws.affair.dig("overtime", "night_time", "end_hour")
    time.change(hour: 0, min: 0, sec: 0).advance(hours: hour)
  end

  def working_minute(time, enter = nil, leave = nil)
    start_at = affair_start(time)
    end_at = affair_end(time)

    if enter
      start_at = enter > start_at ? enter : start_at
    end
    if leave
      end_at = leave > end_at ? end_at : leave
    end

    break_start_at = affair_break_start(time)
    break_end_at = affair_break_end(time)

    minutes, _ = Gws::Affair::Utils.time_range_minutes(start_at..end_at, break_start_at..break_end_at)
    minutes
  end

  def overtime_in_work?
    false
  end
end
