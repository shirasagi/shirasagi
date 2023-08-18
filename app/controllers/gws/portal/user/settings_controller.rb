class Gws::Portal::User::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter
  include Gws::Portal::UserPortalFilter

  model Gws::Portal::UserSetting

  prepend_view_path 'app/views/gws/portal/common/settings'
  navi_view 'gws/portal/main/navi'
  menu_view 'gws/crud/resource_menu'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    set_portal_setting
    if @cur_user == @portal_user
      @crumbs << [t("gws/portal.user_portal"), gws_portal_user_path]
    else
      @crumbs << [@portal_user.name, gws_portal_user_path]
    end
    @crumbs << [t("gws/portal.links.settings"), action: :show]
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
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    show_setting
  end
end
