module Gws::Portal::PortalFilter
  extend ActiveSupport::Concern

  included do
    helper Gws::Schedule::PlanHelper
    menu_view "gws/portal/common/portal/menu"
  end

  private

  # override Gws::BaseFilter#set_gws_assets
  def set_gws_assets
    super
    javascript("gws/calendar", defer: true)
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  # must be overridden by sub-class
  def set_portal_setting
    raise NotImplementedError
  end

  def save_portal_setting
    return unless @portal.new_record?

    raise '403' unless @portal.allowed?(:edit, @cur_user, site: @cur_site, strict: true)
    raise '403' unless @portal.save
    @portal.save_default_portlets
  end

  public

  def show_portal
    if @portal.blank?
      render template: "gws/portal/common/portal/no_portals"
      return
    end

    raise '403' unless @portal.portal_readable?(@cur_user, site: @cur_site)

    @items = @portal.portlets.presence || @portal.default_portlets
    @items.select! do |item|
      @cur_site.menu_visible?(item.portlet_model) && Gws.module_usable?(item.portlet_model, @cur_site, @cur_user)
    end

    if @portal.show_portal_notice?
      @sys_notices = Sys::Notice.and_public.gw_admin_notice.reorder(notice_severity: 1, released: -1).page(1).per(5)

      if Gws.module_usable?(:notice, @cur_site, @cur_user)
        @notices = Gws::Notice::Post.site(@cur_site).without_deleted.and_public.
          readable(@cur_user, site: @cur_site)

        case @portal.portal_notice_browsed_state
        when 'read'
          @notices = @notices.and_read(@cur_user)
        when 'both'
          # nothing to do
        else # unread
          @notices = @notices.and_unread(@cur_user)
        end
        @notices = @notices.search_severity(severity: @portal.portal_notice_severity)
        @notices = @notices.reorder(severity: -1, released: -1)
        @notices = @notices.page(1).per(5)
      else
        @notices = Gws::Notice::Post.none
      end
    end

    if Gws.module_usable?(:monitor, @cur_site, @cur_user) && @portal.show_portal_monitor?
      @monitors = Gws::Monitor::Topic.site(@cur_site).topic.
        and_public.
        and_attended(@cur_user, site: @cur_site, group: @cur_group).
        and_unanswered(@cur_group).
        and_noticed
    else
      @monitors = Gws::Monitor::Topic.none
    end

    if @portal.show_portal_link?
      @links = Gws::Link.site(@cur_site).and_public.
        readable(@cur_user, site: @cur_site).to_a
    end

    render template: "gws/portal/common/portal/show"
  end

  def show_setting
    render
  end

  def show_layout
    @items = @portal.portlets
    render template: 'gws/portal/common/layouts/show'
  end

  def update_layout
    @items = @portal.portlets.to_a
    id_item_map = @items.index_by { |item| item.id.to_s }

    error_messages = []
    ActiveSupport::JSON.decode(params.require(:json)).each do |id, data|
      item = id_item_map[id]
      next unless item

      item.grid_data = data
      if !item.save
        Rails.logger.warn { item.errors.full_messages.join("\n") }
        error_messages += item.errors.full_messages
      end
    end

    if error_messages.present?
      render json: { message: error_messages.join("\n") }.to_json, status: :bad_request
    else
      render json: { message: t("ss.notice.saved") }.to_json
    end
  rescue => e
    Rails.logger.error { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    render json: { message: e.to_s }.to_json, status: :bad_request
  end
end
