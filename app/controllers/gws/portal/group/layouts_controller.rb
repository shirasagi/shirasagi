class Gws::Portal::Group::LayoutsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Portal::PortalFilter

  model Gws::Portal::GroupSetting

  navi_view 'gws/portal/main/navi'
  menu_view 'gws/portal/common/layouts/menu'

  before_action :set_portal_setting
  before_action :save_portal_setting

  private

  def set_crumbs
    if @cur_site.id.to_s == params[:group].to_s
      @crumbs << [t("gws/portal.root_portal"), gws_portal_group_path]
    else
      @crumbs << [t("gws/portal.group_portal"), gws_portal_group_path]
    end
    @crumbs << [t("gws/portal.links.arrange_portlets"), action: :show]
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
    show_layout
  end

  def update
    update_layout
  end
end
