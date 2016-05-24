require 'rss'

class Rss::ImportJob < Cms::ApplicationJob

  attr_reader :errors

  class << self
    def register_jobs(site, user = nil)
      Rss::Node::Page.site(site).and_public.each do |node|
        register_job(site, node, user)
      end
    end

    def register_job(site, node, user = nil)
      if node.try(:rss_refresh_method) == Rss::Node::Page::RSS_REFRESH_METHOD_AUTO
        bind(site_id: site.host, node_id: node.id, user_id: user.present? ? user.id : nil).perform_later
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end
  end

  def perform
    return unless site
    return unless node

    Rails.logger.info("start importing rss from #{node.rss_url}")

    @rss_links = []
    @min_released = nil
    @max_released = nil
    @errors = []

    Rss::Wrappers.parse(node.rss_url).each do |item|
      import_rss_item item
    end

    # remove unimported pages
    remove_unimported_pages

    # remove old pages
    Rss::Page.limit_docs(site, node, node.rss_max_docs) do |item|
      put_history_log(item, :destroy)
    end

    Rails.logger.info("finish importing rss from #{node.rss_url}")
    @errors.empty?
  end

  def import_rss_item(rss_item)
    return if rss_item.link.blank? || rss_item.name.blank?

    update_stats rss_item

    page = Rss::Page.site(site).node(node).where(rss_link: rss_item.link).first
    return if newer_than?(page, rss_item)
    page ||= Rss::Page.new
    page.cur_site = site
    page.cur_node = node
    page.cur_user = user if user.present?
    page.name = rss_item.name
    page.layout_id = node.page_layout_id if node.page_layout_id.present?
    page.rss_link = rss_item.link
    page.html = rss_item.html
    page.released = rss_item.released
    page.permission_level = node.permission_level if page.permission_level.blank?
    page.group_ids = Array.new(node.group_ids) if page.group_ids.blank?
    unless save_or_update page
      Rails.logger.error(page.errors.full_messages.to_s)
      @errors.concat(page.errors.full_messages)
    end
  end

  def update_stats(rss_item)
    @rss_links << rss_item.link
    @min_released = rss_item.released if @min_released.blank? || @min_released > rss_item.released
    @max_released = rss_item.released if @max_released.blank? || @max_released < rss_item.released
  end

  def newer_than?(page, rss_item)
    page.present? && page.released >= rss_item.released
  end

  def save_or_update(page)
    if user
      raise "403" unless page.allowed?(:edit, user)
      if page.state == "public"
        raise "403" unless page.allowed?(:release, user)
      end
    end

    # put_history_log(page)
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
    return if @rss_links.blank? || @min_released.blank? || @max_released.blank?

    criteria = Rss::Page.site(site).node(node)
    criteria = criteria.between(released: @min_released..@max_released)
    criteria = criteria.nin(rss_link: @rss_links)
    criteria.each do |item|
      item.destroy
      put_history_log(item, :destroy)
    end
  end

  def put_history_log(page, action)
    log = History::Log.new
    log.url          = Rails.application.routes.url_helpers.import_rss_pages_path site.host, node
    log.controller   = "rss/pages"
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
