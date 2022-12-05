module Gws::Addon::User::DutyHour
  extend ActiveSupport::Concern
  extend SS::Addon

  def effective_duty_calendar(site)
    shift_calendar(site) || default_duty_calendar(site)
  end

  def default_duty_calendar(site)
    duty_calendar = Gws::Affair::DutyCalendar.site(site).in(member_ids: id).order_by(id: 1).first
    return duty_calendar if duty_calendar.present?

    main_group = gws_main_group(site)
    if main_group.present?
      duty_calendar = Gws::Affair::DutyCalendar.site(site).in(member_group_ids: main_group.id).order_by(id: 1).first
    end
    return duty_calendar if duty_calendar.present?

    Gws::Affair::DefaultDutyCalendar.new(cur_site: site, cur_user: self)
  end

  # シフト勤務機能は利用停止
  def shift_calendar(site)
    #Gws::Affair::ShiftCalendar.site(site).user(self).first
    nil
  end

  def effective_capital_year(site)
    date = Time.zone.today
    ::Gws::Affair::CapitalYear.site(site).where({ :start_date.lte => date , :close_date.gte => date }).first
  end

  def effective_capital(site)
    @_effective_capital_year ||= effective_capital_year(site)
    return nil unless @_effective_capital_year

    # in member
    capital = ::Gws::Affair::Capital.
      where(year_id: @_effective_capital_year.id).
      in(member_ids: [id]).
      first

    # in member groups
    capital ||= ::Gws::Affair::Capital.
      where(year_id: @_effective_capital_year.id).
      in(member_group_ids: group_ids).
      first

    capital
  end
end
