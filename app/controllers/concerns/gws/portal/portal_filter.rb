module Gws::Portal::PortalFilter
  extend ActiveSupport::Concern

  included do
    helper Gws::Schedule::PlanHelper
    #before_action :set_portal_setting
  end

  private

  def set_portal_setting
    return if @portal

    if params[:group].present?
      @portal_group = Gws::Group.find(params[:group])
      @portal = @portal_group.find_portal_setting(cur_user: @cur_user, cur_site: @cur_site)
      @portal.portal_type = (@portal_group.id == @cur_site.id) ? :root_portal : :group_portal
    else
      @portal_user = Gws::User.find(params[:user]) if params[:user].present?
      @portal_user ||= @cur_user
      @portal = @portal_user.find_portal_setting(cur_user: @cur_user, cur_site: @cur_site)
      @portal.portal_type = (@portal_user.id == @cur_user.id) ? :my_portal : :user_portal
    end

    return if @portal.my_portal?
    raise '403' unless @portal.portal_readable?(@cur_user, site: @cur_site)
  end

  def save_portal_setting
    return unless @portal.new_record?

    raise '403' unless @portal.allowed?(:edit, @cur_user, site: @cur_site, strict: true)
    raise '403' unless @portal.save
    @portal.save_default_portlets
  end

  public

  def show_portal
    @items = @portal.portlets.presence || @portal.default_portlets
    @items.select! { |item| @cur_site.menu_visible?(item.portlet_model) }
    render file: "gws/portal/common/portal/show"
  end

  def show_setting
    render
  end

  def show_layout
    @items = @portal.portlets
    render file: 'gws/portal/common/layouts/show'
  end

  def update_layout
    @items = @portal.portlets.to_a

    ActiveSupport::JSON.decode(params.require(:json)).each do |id, data|
      item = @items.find { |c| c.id.to_s == id }
      next unless item

      item.grid_data = data
      if !item.save
        Rails.logger.warn(item.errors.full_messages.join("\n"))
      end
    end

    render json: { message: t("ss.notice.saved") }.to_json
  end
end
