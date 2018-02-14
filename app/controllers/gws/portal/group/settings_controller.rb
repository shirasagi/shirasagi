class Gws::Portal::Group::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::GroupSetting

  prepend_view_path 'app/views/gws/portal/common/settings'
  navi_view 'gws/portal/main/navi'
  menu_view 'gws/crud/resource_menu'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    set_portal_setting
    @crumbs << [@cur_site.menu_portal_label || t("modules.gws/portal"), gws_portal_path]
    @crumbs << [@portal.group_name, gws_portal_group_path]
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
    show_setting
  end
end
