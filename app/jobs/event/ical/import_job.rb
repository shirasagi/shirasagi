class Event::Ical::ImportJob < Cms::ApplicationJob

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

    Rails.logger.info("start importing ics")

    if @events.present?
      today = Time.zone.now.to_date
      pages = Cms::Page.site(site).select{ |page| @events.collect(&:url).collect(&:to_s).include?(page.full_url) }
      @events.each do |event|
        next if node.ical_import_date_ago.present? && event.dtstart.to_date < today - node.ical_import_date_ago.days
        next if node.ical_import_date_after.present? && event.dtstart.to_date > today + node.ical_import_date_after.days
        item = model.site(site).node(node).where(ical_link: event.url.to_s).first || model.new
        item.ical_link = event.url
        next if site_page?(pages, item)
        @ical_links << event.url.to_s
        item.cur_site = site
        item.cur_node = node
        item.cur_user = user
        item.name = item.event_name = event.summary
        item.layout_id = node.page_layout_id if node.page_layout_id.present?
        item.state = node.ical_page_state if node.ical_page_state.present?
        if event.description.present?
          description = event.description
          description = description.push('').join(';') if description.is_a?(Icalendar::Values::Array)
          item.html = Nokogiri::HTML.parse(description).text
        end
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
        item.save
      end
    else
      Rails.logger.info("couldn't parse ics items")
    end

    after_import

    Rails.logger.info("finish importing ics")
    @errors.empty?
  end

  private

  def model
    @model ||= Event::Page.with_repl_master
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
      uri = URI.parse(Cms::Node.find(node_id)[:ical_import_url])
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == 'https'
      req = Net::HTTP::Get.new(uri.path)
      res = http.request(req)
      calendar = Icalendar::Calendar.parse(res.body)
      @events = calendar.first.events
    rescue => e
      Rails.logger.info("Icalendar::Calendar.parse failer (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
      @errors << "Icalendar::Calendar.parse failer (#{e.message}):\n  #{e.backtrace.join("\n  ")}"
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

  def remove_unimported_pages
    return if @ical_links.blank?

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
