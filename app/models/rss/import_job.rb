require 'rss'

class Rss::ImportJob
  include Job::Worker

  attr_reader :errors

  class << self
    def register_jobs(site, user = nil)
      Rss::Node::Page.site(site).public.each do |node|
        register_job(site, node, user)
      end
    end

    def register_job(site, node, user = nil)
      if node.try(:rss_refresh_method) == Rss::Node::Page::RSS_REFRESH_METHOD_AUTO
        call_async(site.host, node.id, user.present? ? user.id : nil) do |job|
          job.site_id = site.id
          job.user_id = user.id if user.present?
        end
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end
  end

  def call(host, node, user)
    @cur_site = Cms::Site.find_by(host: host)
    return unless @cur_site
    @cur_node = Rss::Node::Page.site(@cur_site).public.or({id: node}, {filename: node}).first
    return unless @cur_node
    @cur_user = Cms::User.site(@cur_site).or({id: user}, {name: user}).first if user.present?

    Rails.logger.info("start importing rss from #{@cur_node.rss_url}")

    @imported_links = []
    @min_released = nil
    @max_released = nil
    @errors = []

    rss = RSS::Parser.parse(@cur_node.rss_url, false)
    traverse_items(rss) do |item|
      import_rss_item item
    end

    # remove unimported pages
    remove_unimported_pages

    # remove old pages
    Rss::Page.limit_docs(@cur_site, @cur_node, @cur_node.rss_max_docs) do |item|
      put_history_log(item, :destroy)
    end

    Rails.logger.info("finish importing rss from #{@cur_node.rss_url}")
    @errors.empty?
  end

  def import_rss_item(rss_item)
    return if rss_item.link.blank? || rss_item.name.blank?

    page = Rss::Page.site(@cur_site).node(@cur_node).where(rss_link: rss_item.link).first
    return if page.present? && page.released >= rss_item.released
    page ||= Rss::Page.new
    page.cur_site = @cur_site
    page.cur_node = @cur_node
    page.cur_user = @cur_user if @cur_user.present?
    page.name = rss_item.name
    page.layout_id = @cur_node.page_layout_id if @cur_node.page_layout_id.present?
    # page.state = @cur_node.state
    # page.category_ids = Array.new(@cur_node.category_ids) if @cur_node.category_ids.present?
    page.rss_link = rss_item.link
    page.html = rss_item.html
    page.released = rss_item.released
    if save_or_update page
      @imported_links << page.rss_link
      @min_released = page.released if @min_released.blank? || @min_released > page.released
      @max_released = page.released if @max_released.blank? || @max_released < page.released
    else
      Rails.logger.error("#{page.errors.full_messages}")
      @errors.concat(page.errors.full_messages)
    end
  end

  def traverse_items(rss, &block)
    case rss
    when RSS::Atom::Feed
      Rss::Wrappers::Atom.wrap(rss).each(&block)
    when RSS::Rss
      Rss::Wrappers::Rss.wrap(rss).each(&block)
    when RSS::RDF
      Rss::Wrappers::RDF.wrap(rss).each(&block)
    end
  end

  def save_or_update(page)
    if @cur_user
      raise "403" unless page.allowed?(:edit, @cur_user)
      if page.state == "public"
        raise "403" unless page.allowed?(:release, @cur_user)
      end
    end

    # put_history_log(page)
    if page.new_record?
      log_msg = "create #{page.class.to_s.underscore}(#{page.id})"
      log_msg = "#{log_msg} by #{@cur_user.name}(#{@cur_user.id})" if @cur_user
      Rails.logger.info(log_msg)
      put_history_log(page, :create)
      ret = page.save
    else
      log_msg = "update #{page.class.to_s.underscore}(#{page.id})"
      log_msg = "#{log_msg} by #{@cur_user.name}(#{@cur_user.id})" if @cur_user
      Rails.logger.info(log_msg)
      put_history_log(page, :update)
      ret = page.update
    end
    ret
  end

  def remove_unimported_pages
    return if @imported_links.blank? || @min_released.blank? || @max_released.blank?

    criteria = Rss::Page.site(@cur_site).node(@cur_node)
    criteria = criteria.between(released: @min_released..@max_released)
    criteria = criteria.nin(:rss_link, @imported_links)
    criteria.each do |item|
      item.destroy
      put_history_log(item, :destroy)
    end
  end

  def put_history_log(page, action)
    log = History::Log.new
    log.url          = Rails.application.routes.url_helpers.import_rss_pages_path @cur_site.host, @cur_node
    log.controller   = "rss/pages"
    log.user_id      = @cur_user.id if @cur_user
    log.site_id      = @cur_site.id if @cur_site
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