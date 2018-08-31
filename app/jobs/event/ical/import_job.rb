class Event::Ical::ImportJob < Cms::ApplicationJob

  queue_as :external

  ICAL_WEEKDAYS = %w(SU MO TU WE TH FR SA).freeze
  ICAL_WEEKDAY_MAP = Hash[ICAL_WEEKDAYS.map.with_index { |wday, index| [wday, index] }].freeze

  class << self
    def register_jobs(site, user = nil)
      Event::Node::Page.site(site).and_public.each do |node|
        register_job(site, node, user)
      end
    end

    def register_job(site, node, user = nil)
      return if node.try(:ical_refresh_disabled?)

      if node.try(:ical_refresh_auto?)
        bind(site_id: site.id, node_id: node.id, user_id: user.present? ? user.id : nil).perform_later
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end

    def validate_ical(path)
      open(path) do |io|
        ::Icalendar::Calendar.parse(io)
      end
      true
    rescue
      false
    end
  end

  class DaysInMonthEnumerator
    include Enumerable

    def initialize(from, to, interval)
      @from = from
      @to = to
      @interval = interval
    end

    def each
      0.step(by: @interval) do |n|
        start_month = @from + n.months
        break if start_month > @to

        end_month = start_month + 1.month
        end_month = @to if end_month > @to

        d = start_month
        while d < end_month
          yield d
          d += 1.day
        end
      end
    end
  end

  def perform(*args)
    before_import(*args)

    if @calendars.present?
      Rails.logger.info("start importing calendars. there are #{@calendars.length} calendars.")
      import_ical_calendars
    else
      Rails.logger.info("there are no calendars")
    end

    after_import

    Rails.logger.info("finish importing calendars")
  ensure
    @files.destroy_all if @files
  end

  private

  def model
    @model ||= Event::Page.with_repl_master
  end

  def before_import(*args)
    @ical_uids = []
    @max_dates_size = Event::Page::MAX_EVENT_DATES_SIZE
    @options = args.extract_options!

    if args.present? && SS::File.in(id: args).exists?
      @files = SS::File.in(id: args)
      @calendars = []
      @files.each do |file|
        open(file.path) do |io|
          @calendars += ::Icalendar::Calendar.parse(io)
        end
      end
    else
      @calendars = node.ical_parse
    end
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

    now = Time.zone.now
    if node.ical_import_date_ago.present?
      @min_day = (now - node.ical_import_date_ago.days).beginning_of_day
    else
      @min_day = (now - SS.config.event.ical_import_date_ago.days).beginning_of_month
    end
    if node.ical_import_date_after.present?
      @max_day = (now + node.ical_import_date_after.days).end_of_day
    else
      @max_day = (now + SS.config.event.ical_import_date_after.days).end_of_month
    end

    @events = calendar.events
    if @events.blank?
      Rails.logger.info("#{calendar_name}: there are no events in the calendar")
      return
    end

    Rails.logger.debug("#{calendar_name}: there are #{@events.length} events in the calendar")
    import_ical_events
  ensure
    Time.zone = save_time_zone if save_time_zone
  end

  def import_ical_events
    @events.each do |event|
      begin
        uid = extract_text(event.uid)

        # uid is required. if absent, we simply ignore it.
        next if uid.blank?

        # recurrence_id が設定されたイベントは、繰り返しイベントの一部が変更されたもの。
        # recurrence_id が設定されており、すでに取り込み済みの場合は、単に無視する。
        # ※シラサギでは繰り返しイベントの一部を変更したイベントはサポートしない。
        next if event.recurrence_id.present? && @ical_uids.include?(uid)

        @ical_uids << uid
        import_ical_event(event)
      rescue => e
        Rails.logger.info("event import failure (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def import_ical_event(event)
    item = build_event_page(event)
    return unless item

    return item if save_or_update(item)

    Rails.logger.error(item.errors.full_messages.to_s)
    nil
  end

  def build_event_page(event)
    uid = extract_text(event.uid)
    return if uid.blank?

    last_modified = extract_time(event.last_modified)

    item = model.site(site).node(node).where(ical_uid: uid).first || model.new
    return item if item.persisted? && last_modified && item.updated >= last_modified

    event_dates = generate_event_dates(event)
    return if event_dates.blank?

    item.cur_site = site
    item.cur_node = node
    item.cur_user = user
    item.layout_id = node.page_layout_id if node.page_layout_id.present?
    item.state = node.ical_page_state if node.ical_page_state.present?
    item.permission_level = node.permission_level if item.permission_level.blank?
    item.group_ids = Array.new(node.group_ids) if item.group_ids.blank?

    item.ical_uid = uid
    item.event_dates = event_dates
    item.ical_link = extract_text(event.url)
    item.name = item.event_name = extract_text(event.summary)
    item.summary_html = item.content = extract_text(event.description)
    item.venue = extract_text(event.location)
    item.contact = extract_text(event.contact)
    item.schedule = extract_text(event.x_shirasagi_schedule)
    item.related_url = extract_text(event.x_shirasagi_relatedurl)
    item.cost = extract_text(event.x_shirasagi_cost)
    item.released = extract_time(event.x_shirasagi_released)

    item
  end

  def generate_event_dates(event)
    from = extract_time(event.dtstart)
    to = extract_time(event.dtend)

    if to
      event_dates = day_range([], from, to)
    else
      event_dates = day_range([], from, from + 1.day)
    end

    evaluate_rrule(event_dates, event.rrule, dtstart: from)
    evaluate_rdate(event_dates, event.rdate)
    evaluate_exdate(event_dates, event.exdate)

    event_dates.uniq!
    event_dates.sort!
    event_dates.select! { |d| @min_day <= d && d <= @max_day }
    event_dates.map! { |d| d.strftime("%Y/%m/%d") }
    event_dates = event_dates.take(@max_dates_size) if event_dates.length > @max_dates_size
    event_dates.join("\r\n")
  end

  def evaluate_rrule(event_dates, rrule, dtstart:)
    return event_dates if rrule.blank? || event_dates.length > @max_dates_size

    case rrule
    when Array
      rrule.each { |v| evaluate_rrule(event_dates, v, dtstart: dtstart) }
      event_dates.uniq!
    when Icalendar::Values::Recur
      evaluate_recur(event_dates, rrule, dtstart: dtstart)
    end

    event_dates
  end

  def evaluate_recur(event_dates, recur, dtstart:)
    case recur.frequency.to_s.upcase
    when "DAILY"
      evaluate_recur_daily(event_dates, recur, dtstart: dtstart)
    when "WEEKLY"
      evaluate_recur_weekly(event_dates, recur, dtstart: dtstart)
    when "MONTHLY"
      evaluate_recur_monthly(event_dates, recur, dtstart: dtstart)
    end

    event_dates
  end

  def evaluate_recur_daily(event_dates, recur, dtstart:)
    to = @max_day
    options = { interval: recur.interval || 1 }

    if recur.until.present?
      to = extract_time(recur.until) + 1.day
    end

    if recur.count.present?
      options[:count] = recur.count
    end

    day_range(event_dates, dtstart, to, options)
  end

  def evaluate_recur_weekly(event_dates, recur, dtstart:)
    wdays = recur.by_day
    return event_dates if wdays.blank?

    wdays.map! { |wday| ICAL_WEEKDAY_MAP[wday.to_s.upcase] }.compact
    return event_dates if wdays.blank?

    to = @max_day
    options = { wdays: wdays, interval: recur.interval || 1 }

    if recur.until.present?
      to = extract_time(recur.until) + 1.day
    end

    if recur.count.present?
      options[:count] = recur.count
    end

    week_range(event_dates, dtstart, to, options)
  end

  def evaluate_recur_monthly(event_dates, recur, dtstart:)
    to = @max_day
    options = { interval: recur.interval || 1 }

    if recur.until.present?
      to = extract_time(recur.until) + 1.day
    end

    if recur.count.present?
      options[:count] = recur.count
    end

    if recur.by_day.present?
      options[:days] = recur.by_day
    end

    if recur.by_month_day.present?
      options[:days_of_month] = recur.by_month_day.map(&:to_i)
    end

    month_range(event_dates, dtstart, to, options)
  end

  def evaluate_rdate(event_dates, rdate)
    return event_dates if rdate.blank? || event_dates.length > @max_dates_size

    case rdate
    when Array
      rdate.each { |v| evaluate_rdate(event_dates, v) }
      event_dates.uniq!
    when Icalendar::Values::Period
      evaluate_period(event_dates, rdate)
    else
      val = extract_time(rdate)
      if val && !event_dates.include?(val)
        event_dates << val
      end
    end

    event_dates
  end

  def evaluate_period(event_dates, period)
    period_start = extract_time(period.period_start)
    if period.explicit_end.present?
      explicit_end = extract_time(period.explicit_end)
      day_range(event_dates, period_start.beginning_of_day, explicit_end.end_of_day)
    elsif period.duration.present?
      duration = period.duration
      implicit_end = period_start
      implicit_end += duration.weeks.weeks
      implicit_end += duration.days.days
      implicit_end += duration.hours.hours
      implicit_end += duration.minutes.minutes
      implicit_end += duration.seconds.seconds

      day_range(event_dates, period_start.beginning_of_day, implicit_end.end_of_day)
    end

    event_dates
  end

  def evaluate_exdate(event_dates, exdate)
    return event_dates if exdate.blank?

    case exdate
    when Array
      exdate.each { |v| evaluate_exdate(event_dates, v) }
    else
      val = extract_time(exdate)
      if val
        event_dates.delete(val)
      end
    end

    event_dates
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
      if value.is_a?(DateTime)
        if ical_value.tz_utc
          value.in_time_zone
        else
          Time.zone.local_to_utc(value).in_time_zone
        end
      elsif value.respond_to?(:in_time_zone)
        value.in_time_zone
      end
    elsif ical_value.is_a?(String)
      extract_time(Icalendar::Values::DateOrDateTime.new(ical_value).call)
    elsif value.respond_to?(:to_time)
      value.to_time.in_time_zone
    end
  end

  def day_range(dates, from, to, interval: 1, count: nil)
    from = @min_day if from < @min_day
    to = @max_day if to > @max_day

    i = from
    c = 0
    while i < to
      if !dates.include?(i)
        dates << i
        break if dates.length > @max_dates_size
      end

      i += interval.days
      c += 1
      break if count && c >= count
    end

    dates
  end

  def week_range(dates, from, to, options)
    from = @min_day if from < @min_day
    to = @max_day if to > @max_day
    interval = options[:interval]
    count = options[:count]
    wdays = options[:wdays]

    c = 0
    while from < to
      week_end = from + 7.days
      week_end = to if week_end > to
      days = day_range([], from, week_end)
      days.select! { |d| wdays.include?(d.wday) }

      days.each do |d|
        break if dates.length > @max_dates_size

        if !dates.include?(d)
          dates << d
        end

        c += 1
        break if count && c >= count
      end

      from += interval.weeks
      break if dates.length > @max_dates_size
      break if count && c >= count
    end

    dates
  end

  def month_range(dates, from, to, options)
    from = @min_day if from < @min_day
    to = @max_day if to > @max_day
    interval = options[:interval]
    count = options[:count]
    days = options[:days]
    days_of_month = options[:days_of_month]
    c = 0

    e = DaysInMonthEnumerator.new(from, to, interval)
    e = e.lazy.select do |d|
      if days_of_month
        next true if days_of_month.include?(d.day)

        reverse_day = d.end_of_month.day - d.day + 1
        next true if days_of_month.include?(- reverse_day)
      end

      if days
        weeks = get_month_weeks(d)
        next weeks.any? { |w| days.include?(w) }
      end

      false
    end
    e.each do |d|
      if !dates.include?(d)
        dates << d
      end

      c += 1
      break if count && c >= count
      break if dates.length > @max_dates_size
    end

    dates
  end

  def get_month_weeks(date)
    sym = ICAL_WEEKDAYS[date.wday]

    ret = []
    ret << sym

    get_week = ->(day) do
      weeks = day / 7
      reminder = day % 7
      weeks += 1 if reminder > 0
      weeks
    end

    weeks = get_week.call(date.day)
    ret << "#{weeks}#{sym}"

    reverse_weeks = get_week.call(date.end_of_month.day - date.day + 1)
    ret << "-#{reverse_weeks}#{sym}"

    ret
  end

  def after_import
    sync = @options[:sync]
    sync = node.ical_sync_full? if sync.nil?
    if sync
      # remove unimported pages
      remove_unimported_pages
    end

    # remove old pages
    if node.ical_refresh_enabled?
      model.limit_docs(site, node, node.ical_max_docs) do |item|
        put_history_log(item, :destroy)
      end
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

    ret = page.save
    if ret
      log_msg = "#{action} #{page.class.to_s.underscore}(#{page.id})"
      log_msg += " by #{user.name}(#{user.id})" if user
      Rails.logger.info(log_msg)
      put_history_log(page, action)
    end

    ret
  end

  def remove_unimported_pages
    return unless @ical_uids

    criteria = model.site(site).node(node)
    criteria = criteria.nin(ical_uid: @ical_uids)
    criteria.each do |item|
      item.destroy
      put_history_log(item, :destroy)
    end
  end

  def put_history_log(page, action)
    log = History::Log.new
    log.url          = Rails.application.routes.url_helpers.import_event_pages_path site, node
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
