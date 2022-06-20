class Event::Page::IcalImporter

  ICAL_WEEKDAYS = %w(SU MO TU WE TH FR SA).freeze
  ICAL_WEEKDAY_MAP = Hash[ICAL_WEEKDAYS.map.with_index { |wday, index| [wday, index] }].freeze

  attr_reader :site, :node, :user

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

  def initialize(site, node, user)
    @site = site
    @node = node
    @user = user
  end

  def import(*args)
    before_import(*args)

    if @calendars.present?
      put_log("start importing calendars. there are #{@calendars.length} calendars.")
      import_ical_calendars
    else
      put_log("there are no calendars")
    end

    after_import

    put_log("finish importing calendars")
  ensure
    @files.destroy_all if @files
  end

  private

  def model
    @model ||= Event::Page.with_repl_master
  end

  def put_log(message)
    if @task
      @task.log(message)
    else
      Rails.logger.info(message)
    end
  end

  def before_import(*args)
    @ical_uids = []
    @max_dates_size = Event::Page::MAX_EVENT_DATES_SIZE
    @options = args.extract_options!
    @task = @options[:task]

    if args.present? && SS::File.in(id: args).exists?
      @files = SS::File.in(id: args)
      @calendars = []
      @files.each do |file|
        ::File.open(file.path) do |io|
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
      put_log("#{calendar_name}: set time zone to #{time_zone_id}")
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
      put_log("#{calendar_name}: there are no events in the calendar")
      return
    end

    Rails.logger.debug { "#{calendar_name}: there are #{@events.length} events in the calendar" }
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
        put_log("event import failure (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      end
    end
  end

  def import_ical_event(event)
    item = build_event_page(event)
    return unless item

    if user && !item.allowed?(:import, user, site: site, node: node)
      return
    end

    return item if save_or_update(item)

    Rails.logger.error(item.errors.full_messages.to_s)
    nil
  end

  def build_event_page(event)
    item = find_or_build(event)
    return unless item
    return if user && !item.allowed?(:import, user, site: site, node: node)

    item.ical_link ||= extract_text(event.url)
    item.name = item.event_name = extract_text(event.summary)
    item.summary_html = item.content = extract_text(event.description)
    item.venue = extract_text(event.location)
    item.contact = extract_text(event.contact)
    item.schedule = extract_text(event.x_shirasagi_schedule)
    item.related_url = extract_text(event.x_shirasagi_relatedurl)
    item.cost = extract_text(event.x_shirasagi_cost)
    item.released = extract_time(event.x_shirasagi_released)

    add_event_recurrences(item, event)

    item
  end

  def find_or_build(event)
    uid = extract_text(event.uid)
    return if uid.blank?
    return if event.dtstart.blank?

    item = find_or_new(event)

    item.cur_site = site
    item.cur_node = node
    item.cur_user = user
    item.layout_id ||= node.page_layout_id
    item.state ||= node.ical_page_state if node.ical_page_state.present?
    item.category_ids = Array.new(node.ical_category_ids) if item.category_ids.blank?
    item.permission_level = node.permission_level if item.permission_level.blank?
    item.group_ids = Array.new(node.group_ids) if item.group_ids.blank?
    item.ical_uid ||= extract_text(event.x_shirasagi_parent_uid).presence || uid

    item
  end

  def find_or_new(event)
    uid = extract_text(event.uid)
    parent_uid = extract_text(event.x_shirasagi_parent_uid)
    if parent_uid.present?
      item = model.site(site).node(node).where(ical_uid: parent_uid).first
      item.event_recurrences = nil if item
    end
    item ||= model.site(site).node(node).where(ical_uid: uid).first
    item ||= model.new
    item
  end

  def add_event_recurrences(item, event)
    recurrences = Array(item.event_recurrences)
    if event.rrule.present? || event.rdate.present?
      recurrences_with_rrule(recurrences, item, event) if event.rrule.present?
      recurrences_with_rdate(recurrences, item, event) if event.rdate.present?
    else
      recurrences_without_recur(recurrences, item, event)
    end

    item.event_recurrences = recurrences
  end

  def recurrences_with_rrule(recurrences, item, event)
    return recurrences if event.rrule.blank?

    kind = event.dtstart.is_a?(Icalendar::Values::Date) ? "date" : "datetime"
    exclude_dates = Array(event.exdate).map { |v| extract_time(v) }.map(&:to_date)
    start_at = extract_time(event.dtstart)
    end_at = extract_time(event.dtend) if event.dtend

    Array(event.rrule).each do |rrule|
      case rrule
      when Icalendar::Values::Recur
        items = evaluate_recur(rrule, kind: kind, start_at: start_at, end_at: end_at, excludes: exclude_dates)
        if items.present?
          recurrences.append(*items) # don't use `+=` to append
        end
      end
    end

    recurrences
  end

  def recurrences_with_rdate(recurrences, item, event)
    return recurrences if event.rdate.blank?

    exclude_dates = Array(event.exdate).map { |v| extract_time(v) }.map(&:to_date)
    recurrence_dates = evaluate_rdate(event.rdate)
    start_at = extract_time(event.dtstart)
    end_at = extract_time(event.dtend) if event.dtend
    # don't use `+=` to append
    recurrences.append(*recurrences_from_dates(recurrence_dates, start_at: start_at, end_at: end_at, excludes: exclude_dates))
    recurrences
  end

  def recurrences_without_recur(recurrences, item, event)
    exclude_dates = Array(event.exdate).map { |v| extract_time(v) }.map(&:to_date)
    from = extract_time(event.dtstart)
    to = extract_time(event.dtend) if event.dtend

    if from.hour == 0 && from.min == 0 && from.sec == 0
      kind = "date"
    else
      kind = "datetime"
    end
    start_at = from

    if kind == "datetime"
      end_at = Event.make_time(start_at, to) if to
      end_at ||= start_at.tomorrow.beginning_of_day
    else
      end_at = start_at + 1.day
    end

    until_on = (to - 1.second).to_date if to
    until_on ||= (end_at - 1.second).to_date

    recurrences << {
      kind: kind, start_at: start_at, end_at: end_at, frequency: "daily", until_on: until_on,
      exclude_dates: exclude_dates
    }
    recurrences
  end

  def recurrences_from_dates(recurrence_dates, start_at:, end_at: nil, excludes: nil)
    if start_at.hour == 0 && start_at.min == 0 && start_at.sec == 0
      kind = "date"
    else
      kind = "datetime"
    end

    clustered_dates = Event.cluster_dates(recurrence_dates)
    clustered_dates.map do |dates|
      if kind == "date"
        e = dates.first.tomorrow
      else
        e = Event.make_time(dates.first, end_at) if end_at
        e ||= dates.first.tomorrow.to_date
      end

      { kind: kind, start_at: Event.make_time(dates.first, start_at), end_at: e,
        frequency: "daily", until_on: dates.last.to_date, exclude_dates: excludes }
    end
  end

  def evaluate_recur(recur, kind:, start_at:, end_at:, excludes:)
    case recur.frequency.to_s.upcase
    when "DAILY"
      evaluate_recur_daily(recur, kind: kind, start_at: start_at, end_at: end_at, excludes: excludes)
    when "WEEKLY"
      evaluate_recur_weekly(recur, kind: kind, start_at: start_at, end_at: end_at, excludes: excludes)
    when "MONTHLY"
      evaluate_recur_monthly(recur, kind: kind, start_at: start_at, end_at: end_at, excludes: excludes)
    end
  end

  def evaluate_recur_daily(recur, kind:, start_at:, end_at:, excludes:)
    to = @max_day
    options = { interval: recur.interval || 1 }

    if recur.until.present?
      to = extract_time(recur.until) + 1.day
    end

    if recur.count.present?
      options[:count] = recur.count
    end

    recurrence_dates = day_range(start_at, to, **options)
    recurrences_from_dates(recurrence_dates, start_at: start_at, end_at: end_at, excludes: excludes)
  end

  def evaluate_recur_weekly(recur, kind:, start_at:, end_at:, excludes:)
    wdays = recur.by_day
    return [] if wdays.blank?

    wdays.map! { |wday| ICAL_WEEKDAY_MAP[wday.to_s.upcase] }.compact
    return [] if wdays.blank?

    to = @max_day
    options = { wdays: wdays, interval: recur.interval || 1 }

    if recur.until.present?
      to = extract_time(recur.until) + 1.day
    end

    if recur.count.present?
      options[:count] = recur.count
    end

    recurrence_dates = week_range(start_at, to, options)
    recurrences_from_dates(recurrence_dates, start_at: start_at, end_at: end_at, excludes: excludes)
  end

  def evaluate_recur_monthly(recur, kind:, start_at:, end_at:, excludes:)
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

    recurrence_dates = month_range(start_at, to, options)
    recurrences_from_dates(recurrence_dates, start_at: start_at, end_at: end_at, excludes: excludes)
  end

  def evaluate_rdate(rdate)
    rdate = Array(rdate)
    return [] if rdate.blank?

    ret = rdate.map do |v|
      case v
      when Icalendar::Values::Period
        evaluate_period(v)
      else
        extract_time(v)
      end
    end

    ret.flatten!
    ret.compact!
    ret.uniq!
    ret.sort!
    ret
  end

  def evaluate_period(period)
    period_start = extract_time(period.period_start)
    if period.explicit_end.present?
      explicit_end = extract_time(period.explicit_end)
      day_range(period_start.beginning_of_day, explicit_end.end_of_day)
    elsif period.duration.present?
      duration = period.duration
      implicit_end = period_start
      implicit_end += duration.weeks.weeks
      implicit_end += duration.days.days
      implicit_end += duration.hours.hours
      implicit_end += duration.minutes.minutes
      implicit_end += duration.seconds.seconds

      day_range(period_start.beginning_of_day, implicit_end.end_of_day)
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

  def day_range(from, to, interval: 1, count: nil)
    from = @min_day if from < @min_day
    to = @max_day if to > @max_day

    dates = []
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

  def week_range(from, to, options)
    dates = []
    from = @min_day if from < @min_day
    to = @max_day if to > @max_day
    interval = options[:interval]
    count = options[:count]
    wdays = options[:wdays]

    c = 0
    while from < to
      week_end = from + 7.days
      week_end = to if week_end > to
      days = day_range(from, week_end)
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

  def month_range(from, to, options)
    dates = []
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
      if page.state == "public" && !page.allowed?(:release, user)
        raise "403"
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
      put_log(log_msg)
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

    if page && page.respond_to?(:new_record?) && !page.new_record?
      log.target_id    = page.id
      log.target_class = page.class
    end

    log.save
  end

  class << self
    def validate_ical(path)
      ::File.open(path) do |io|
        ::Icalendar::Calendar.parse(io)
      end
      true
    rescue
      false
    end
  end
end
