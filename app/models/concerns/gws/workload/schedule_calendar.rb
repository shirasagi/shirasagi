module Gws::Workload::ScheduleCalendar
  extend ActiveSupport::Concern
  include Gws::Schedule::CalendarFormat

  included do
    attr_accessor :api, :api_start, :api_end
    permit_params :api, :api_start, :api_end

    before_validation :set_from_drop_date_api, if: -> { api == 'drop' }
  end

  private

  def set_from_drop_date_api
    self.due_date = api_start
  end

  public

  def calendar_format(user, site)
    data = { id: id.to_s, start: due_date, end: due_date, allDay: allday? }

    data[:readable] = readable?(user, site: site)
    data[:editable] = allowed?(:edit, user, site: site)

    data[:title] = I18n.t("gws/schedule.private_plan")
    if data[:readable]
      data[:title] = name

      if html.present?
        data[:sanitizedHtml] = ::ApplicationController.helpers.sanitize(html, tags: []).squish.truncate(120)
      end
    end

    #data[:startDateLabel] = date_label(due_date)
    #data[:startTimeLabel] = nil
    #data[:endDateLabel] = date_label(due_date)
    #data[:endTimeLabel] = nil

    data[:className] = 'fc-event-range'
    data[:className] += ' fc-event-work'

    if allday?
      data[:start] = due_date.to_date
      data[:end] = (due_date + 1.day).to_date
      data[:className] += ' fc-event-allday'
    end

    if (data[:readable] && private_plan?(user)) || data[:title] == I18n.t("gws/schedule.private_plan")
      data[:className] += ' fc-event-private'
    end

    data
  end

  def start_at
    due_date
  end

  def end_at
    due_date
  end

  def allday?
    true
  end

  def date_label(datetime)
    I18n.l(datetime.to_date, format: :gws_long)
  end

  def time_label(datetime)
    sprintf('%d:%02d', datetime.hour, datetime.minute)
  end

  def private_plan?(user)
    return false if readable_custom_group_ids.present?
    return false if readable_group_ids.present?
    readable_member_ids == [user.id] && member_ids == [user.id]
  end

  #def approval_check_plan?
  #  false
  #end
end
