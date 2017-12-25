class Gws::Portal::User::PortalController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::UserSetting

  before_action :set_portal_setting

  private

  def set_crumbs
    set_portal_setting
    if @portal_user == @cur_user
      @crumbs << [t("modules.gws/portal"), gws_portal_user_path(user: @portal_user)]
    else
      @crumbs << [t("gws/portal.user_portal"), gws_portal_setting_users_path]
      @crumbs << [@portal_user.name, gws_portal_user_path(user: @portal_user)]
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_item
    set_portal_setting
    @item = @portal
  end

  public

  def show
    if @portal_user == @cur_user
      @sys_notices = Sys::Notice.and_public.
        gw_admin_notice.
        page(1).per(5)

      @notices = Gws::Notice.site(@cur_site).and_public.
        readable(@cur_user, site: @cur_site).
        page(1).per(5)
    end

    @links = Gws::Link.site(@cur_site).and_public.
      readable(@cur_user, site: @cur_site).to_a

    show_portal
  end
end
