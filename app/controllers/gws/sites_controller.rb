class Gws::SitesController < ApplicationController
  include Gws::BaseFilter
  include SS::CrudFilter
  helper SS::DatetimeHelper

  model Gws::Group

  navi_view "gws/main/conf_navi"
  menu_view 'gws/crud/resource_menu'

  before_action :set_addons, only: %w(show new create edit update)
  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def set_crumbs
    @crumbs << [t("gws.site_info"), action: :show]
  end

  def set_item
    @item = Gws::Group.find(@cur_site.id)
    @item.attributes = fix_params
  end

  def set_addons
    @addons = @item.addons(:organization)
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
