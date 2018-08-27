class Event::Ical::ImportJob < Cms::ApplicationJob

  queue_as :external
  attr_reader :errors

  class << self
    def register_jobs(site, user = nil)
      Event::Node::Ical.site(site).and_public.each do |node|
        register_job(site, node, user)
      end
    end

    def register_job(site, node, user = nil)
      if node.try(:ical_refresh_method) == 'auto'
        bind(site_id: site.id, node_id: node.id, user_id: user.present? ? user.id : nil).perform_later
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end
  end

  def perform(*args)
    before_import(*args)
    return if @errors.present?

    Rails.logger.info("start importing ics")

    if @calendars.present?
      import_ical_calendars
    else
      Rails.logger.info("no ics calendars")
    end

    after_import

    Rails.logger.info("finish importing ics")
    @errors.empty?
  end

  private

  def model
    @model ||= Event::Page.with_repl_master
  end

  def before_import(*args)
    @errors = []
    @ical_links = []

    @calendars = node.ical_parse
  rescue => e
    message = "Icalendar::Calendar.parse failure (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
    Rails.logger.info(message)
    @errors << message
  end

  def import_ical_calendars
    @calendars.each do |calendar|
      import_ical_calendar(calendar)
    end
  end

  def import_ical_calendar(calendar)
    calendar_name = extract_text(calendar.x_wr_calname).presence || calendar.name

    time_zone_id = extract_text(calendar.x_wr_timezone).presence
    time_zone = nil
    save_time_zone = nil
    if time_zone_id
      time_zone = Time.find_zone(time_zone_id)
    end
    if time_zone && time_zone.tzinfo != Time.zone.tzinfo
      save_time_zone = Time.zone
      Time.zone = time_zone
      Rails.logger.info("#{calendar_name}: set time zone to #{time_zone_id}")
    end

    @events = calendar.events
    if @events.blank?
      Rails.logger.info("#{calendar_name}: there are no events in the calendar")
      return
    end

    import_ical_events
  ensure
    Time.zone = save_time_zone if save_time_zone
  end

  def import_ical_events
    @events.each do |event|
      if import_ical_event(event)
        @ical_links << extract_text(event.uid)
      end
    end
  end

  def import_ical_event(event)
    item = build_event_page(event)
    return unless item

    return item if save_or_update(item)

    Rails.logger.error(item.errors.full_messages.to_s)
    @errors.concat(item.errors.full_messages)
    nil
  end

  def build_event_page(event)
    uid = extract_text(event.uid)
    return if uid.blank?

    last_modified = extract_time(event.last_modified)

    item = model.site(site).node(node).where(ical_link: uid).first || model.new
    return item if item.persisted? && last_modified && item.updated >= last_modified

    item.cur_site = site
    item.cur_node = node
    item.cur_user = user
    item.layout_id = node.page_layout_id if node.page_layout_id.present?
    item.state = node.ical_page_state if node.ical_page_state.present?
    item.permission_level = node.permission_level if item.permission_level.blank?
    item.group_ids = Array.new(node.group_ids) if item.group_ids.blank?

    item.ical_link = uid
    item.name = item.event_name = extract_text(event.summary)
    item.summary_html = item.content = extract_text(event.description)
    item.venue = extract_text(event.location)
    item.contact = extract_text(event.contact)
    item.schedule = extract_text(event.x_shirasagi_schedule)
    item.related_url = extract_text(event.x_shirasagi_relatedurl)
    item.cost = extract_text(event.x_shirasagi_cost)
    item.released = extract_time(event.x_shirasagi_released)

    item.event_dates = generate_event_dates(event)
    item
  end

  def generate_event_dates(event)
    from = extract_time(event.dtstart)
    to = extract_time(event.dtend)

    if to
      event_dates = day_range(from, to)
    else
      event_dates = [ from ]
    end

    event_dates += evaluate_rdate(event.rdate)

    event_dates.uniq!
    event_dates.sort!
    event_dates.map { |d| d.strftime("%Y/%m/%d") }.join("\r\n")
  end

  def evaluate_rdate(rdate)
    return [] if rdate.blank?
    return rdate.map { |v| evaluate_rdate(v) }.flatten.uniq if rdate.is_a?(Array)
    return evaluate_period(rdate) if rdate.is_a?(Icalendar::Values::Period)

    val = extract_time(rdate)
    return [] if !val

    [ val ]
  end

  def evaluate_period(period)
    period_start = extract_time(period.period_start)
    if period.explicit_end.present?
      explicit_end = extract_time(period.explicit_end)
      return day_range(period_start.beginning_of_day, explicit_end.end_of_day)
    elsif period.duration.present?
      duration = period.duration
      implicit_end = period_start
      implicit_end += duration.weeks.weeks
      implicit_end += duration.days.days
      implicit_end += duration.hours.hours
      implicit_end += duration.minutes.minutes
      implicit_end += duration.seconds.seconds
      return day_range(period_start.beginning_of_day, implicit_end.end_of_day)
    else
      []
    end
  end

  def extract_text(ical_value)
    return "" if ical_value.blank?
    return ical_value.map(&:to_s).join("\n") if ical_value.is_a?(Array)
    ical_value.to_s
  end

  def extract_time(ical_value)
    return if ical_value.blank?

    if ical_value.is_a?(Icalendar::Values::Date) || ical_value.is_a?(Icalendar::Values::DateTime)
      value = ical_value.value
      case value
      when ::DateTime
        if ical_value.tz_utc
          value.in_time_zone
        else
          Time.zone.local_to_utc(value).in_time_zone
        end
      when ::Date
        value.in_time_zone
      end
    elsif value.respond_to?(:to_time)
      value.to_time.in_time_zone
    end
  end

  def day_range(from, to)
    ret = []

    i = from
    while i < to
      ret << i
      i += 1.day
    end

    ret
  end

  def after_import
    # remove unimported pages
    remove_unimported_pages

    # remove old pages
    model.limit_docs(site, node, node.ical_max_docs) do |item|
      put_history_log(item, :destroy)
    end
  end

  def save_or_update(page)
    return true if !page.changed?

    if user
      raise "403" unless page.allowed?(:edit, user)
      if page.state == "public"
        raise "403" unless page.allowed?(:release, user)
      end
    end

    if page.new_record?
      action = :create
    else
      action = :update
    end

    log_msg = "#{action} #{page.class.to_s.underscore}(#{page.id})"
    log_msg = "#{log_msg} by #{user.name}(#{user.id})" if user
    ret = page.save
    if ret
      Rails.logger.info(log_msg)
      put_history_log(page, action)
    end

    ret
  end

  def remove_unimported_pages
    return unless @ical_links

    criteria = model.site(site).node(node)
    criteria = criteria.nin(ical_link: @ical_links)
    criteria.each do |item|
      item.destroy
      put_history_log(item, :destroy)
    end
  end

  def put_history_log(page, action)
    log = History::Log.new
    log.url          = Rails.application.routes.url_helpers.import_event_icals_path site, node
    log.controller   = "event/pages"
    log.user_id      = user.id if user
    log.site_id      = site.id if site
    log.action       = action

    if page && page.respond_to?(:new_record?)
      if !page.new_record?
        log.target_id    = page.id
        log.target_class = page.class
      end
    end

    log.save
  end
end
