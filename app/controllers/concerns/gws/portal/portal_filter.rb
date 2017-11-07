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
      if @cur_site.id.to_s == params[:group]
        @portal_group = @cur_site
        @portal = @cur_site.find_or_new_portal_root_setting(cur_user: @cur_user, cur_site: @cur_site)
      else
        @portal_group = Gws::Group.find(params[:group])
        @portal = @portal_group.find_or_new_portal_group_setting(cur_user: @cur_user, cur_site: @cur_site)
      end
    elsif params[:user].present?
      @portal_user = Gws::User.find(params[:user])
      @portal = @portal_user.find_or_new_portal_user_setting(cur_user: @cur_user, cur_site: @cur_site)
    else
      @portal_user = @cur_user
      @portal = @cur_user.find_or_new_portal_my_setting(cur_user: @cur_user, cur_site: @cur_site)
    end

    #raise '403' unless @portal.strict_allowed?(:read, @cur_user, site: @cur_site)
  end

  def save_portal_setting
    return unless @portal.new_record?

    raise '403' unless @portal.strict_allowed?(:edit, @cur_user, site: @cur_site)
    raise '403' unless @portal.save
  end

  public

  def show_portal
    @items = @portal.readable_portlets(@cur_user, @cur_site)
    render file: "gws/portal/common/show_portal"
  end

  def show_setting
    render
  end

  def show_layout
    @items = @portal.portlets
    render file: 'gws/portal/common/show_layout'
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
