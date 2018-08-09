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

    if @events.present?
      save_page_by_events
    else
      Rails.logger.info("no ics events")
    end

    after_import

    Rails.logger.info("finish importing ics")
    @errors.empty?
  end

  private

  def model
    @model ||= Event::Page.with_repl_master
  end

  def save_page_by_events
    @today = Time.zone.now.to_date
    @pages = Cms::Page.site(site).select{ |page| @events.collect(&:url).collect(&:to_s).include?(page.full_url) }
    @events.each do |event|
      save_page_by_event(event)
    end
  end

  def save_page_by_event(event)
    return if node.ical_import_date_ago.present? && event.dtstart.to_date < @today - nical_import_date_ago.days
    return if node.ical_import_date_after.present? && event.dtstart.to_date > @today + node.ical_import_date_after.days
    item = model.site(site).node(node).where(ical_link: event.url.to_s).first || model.new
    item.ical_link = event.url
    return if site_page?(@pages, item)
    @ical_links << event.url.to_s
    return if !item.new_record? && item.updated >= event.last_modified.to_datetime
    item.cur_site = site
    item.cur_node = node
    item.cur_user = user
    item.created = event.created
    item.name = item.event_name = event.summary
    item.layout_id = node.page_layout_id if node.page_layout_id.present?
    item.state = node.ical_page_state if node.ical_page_state.present?
    item.html = item.content = event.description
    item.permission_level = node.permission_level if item.permission_level.blank?
    item.group_ids = Array.new(node.group_ids) if item.group_ids.blank?
    item.venue = event.location
    date = event.dtstart.to_date
    end_date = event.dtend.to_date if event.dtend.present?
    event_dates = item.event_dates.split(/\R/).collect(&:to_date) if item.event_dates.present?
    event_dates ||= []
    while date != end_date
      event_dates << date
      date += 1.day
    end
    event_dates.uniq! if event_dates.present?
    item.event_dates = event_dates
    unless save_or_update(item)
      Rails.logger.error(item.errors.full_messages.to_s)
      @errors.concat(item.errors.full_messages)
    end
    item
  end

  def site_page?(pages, item)
    pages.each do |page|
      return true if page.full_url == item.ical_link && page.id != item.id
    end
    false
  end

  def before_import(*args)
    @errors = []
    @ical_links = []

    begin
      calendar = node.ical_parse
      @events = calendar.first.events
    rescue => e
      message = "Icalendar::Calendar.parse failure (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
      Rails.logger.info(message)
      @errors << message
    end
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
    if user
      raise "403" unless page.allowed?(:edit, user)
      if page.state == "public"
        raise "403" unless page.allowed?(:release, user)
      end
    end

    if page.new_record?
      log_msg = "create #{page.class.to_s.underscore}(#{page.id})"
      log_msg = "#{log_msg} by #{user.name}(#{user.id})" if user
      Rails.logger.info(log_msg)
      put_history_log(page, :create)
      ret = page.save
    else
      log_msg = "update #{page.class.to_s.underscore}(#{page.id})"
      log_msg = "#{log_msg} by #{user.name}(#{user.id})" if user
      Rails.logger.info(log_msg)
      put_history_log(page, :update)
      ret = page.update
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
