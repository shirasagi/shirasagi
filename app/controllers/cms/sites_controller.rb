class Cms::SitesController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  helper SS::DatetimeHelper

  model Cms::Site

  navi_view "cms/main/conf_navi"
  menu_view "cms/crud/resource_menu"

  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t("cms.site_info"), action: :show]
  end

  def set_item
    @item = Cms::Site.find(@cur_site.id)
    @item.attributes = fix_params
  end

  def reload_nginx
    if SS.config.ss.updates_and_reloads_nginx_conf
      SS::Nginx::Config.new.write.reload_server
    end
  end

  public

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render
  end

  def update
    @item.attributes = get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_update @item.update
  end
end
