class Sys::SitesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Site

  menu_view "sys/crud/menu"

  before_action :set_search_param
  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def permit_fields
    super + [:upload_policy]
  end

  def set_crumbs
    @crumbs << [t("sys.site"), sys_sites_path]
  end

  def set_search_param
    @s ||= OpenStruct.new(params[:s])
  end

  def reload_nginx
    if SS.config.ss.updates_and_reloads_nginx_conf
      SS::Nginx::Config.new.write.reload_server
    end
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user)
    @items = @model.allow(:read, @cur_user).
      search(@s).
      order_by(_id: -1)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user)
    result = @item.save

    if result
      cond = {
        site_id: @item.id,
        name: I18n.t('cms.roles.admin'),
        permissions: Cms::Role.permission_names,
        permission_level: 3
      }
      role = Cms::Role.find_or_create_by cond

      cms_user = Cms::User.find(@cur_user.id)
      cms_user.add_to_set cms_role_ids: role.id
    end

    render_create result
  end
end
