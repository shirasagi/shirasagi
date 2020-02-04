module Gws::Portal::UserPortalFilter
  extend ActiveSupport::Concern

  private

  def set_portal_setting
    return if @portal

    @portal_user = Gws::User.find(params[:user]) if params[:user].present?
    @portal_user ||= @cur_user
    @portal = @portal_user.find_portal_setting(cur_user: @cur_user, cur_site: @cur_site)
    @portal.portal_type = (@portal_user.id == @cur_user.id) ? :my_portal : :user_portal

    raise '403' unless @portal.portal_readable?(@cur_user, site: @cur_site)
  end
end
