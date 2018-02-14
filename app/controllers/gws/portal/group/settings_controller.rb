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
    if @cur_site.id.to_s == params[:group].to_s
      @crumbs << [t("gws/portal.root_portal"), gws_portal_group_path]
    else
      @crumbs << [t("gws/portal.group_portal"), gws_portal_group_path]
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
    show_setting
  end
end
