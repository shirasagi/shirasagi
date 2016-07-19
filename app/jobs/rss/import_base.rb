require 'rss'

class Rss::ImportBase < Cms::ApplicationJob

  attr_reader :errors

  def perform(*args)
    before_import(*args)

    Rails.logger.info("start importing rss")

    if @items.present?
      @items.each do |item|
        import_rss_item item
      end
    else
      Rails.logger.info("couldn't parse rss items")
    end

    switch_urgency_layout

    after_import

    Rails.logger.info("finish importing rss")
    @errors.empty?
  end

  private
    def model
      @model ||= Rss::Page
    end

    def set_model(model)
      @model = model
    end

    def before_import(*args)
      @rss_links = []
      @min_released = nil
      @max_released = nil
      @errors = []
    end

    def after_import
      # remove unimported pages
      remove_unimported_pages

      # remove old pages
      model.limit_docs(site, node, node.rss_max_docs) do |item|
        put_history_log(item, :destroy)
      end
    end

    def import_rss_item(rss_item)
      return if rss_item.link.blank? || rss_item.name.blank?

      update_stats rss_item

      page = model.site(site).node(node).where(rss_link: rss_item.link).first
      return if newer_than?(page, rss_item)
      page ||= model.new
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
      if rss_item.authors.present?
        rss_item.authors.each do |author|
          page.authors.new(author)
        end
      end
      if node.respond_to?(:page_state)
        page.state = node.page_state.presence || 'public'
      end
      unless save_or_update page
        Rails.logger.error(page.errors.full_messages.to_s)
        @errors.concat(page.errors.full_messages)
      end
      page
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

      criteria = model.site(site).node(node)
      criteria = criteria.between(released: @min_released..@max_released)
      criteria = criteria.nin(rss_link: @rss_links)
      criteria.each do |item|
        item.destroy
        put_history_log(item, :destroy)
      end
    end

    def put_history_log(page, action)
      log = History::Log.new
      log.url          = Rails.application.routes.url_helpers.import_rss_pages_path site, node
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

    def switch_urgency_layout
      return unless node.try(:urgency_enabled?)

      if @items.present? && @items.rss.items.present?
        node.switch_to_urgency_layout
      else
        node.switch_to_default_layout

        ## destroy all pages when switch to default layout
        model.site(site).node(node).each do |item|
          item.destroy
          put_history_log(item, :destroy)
        end
      end
    end
end
