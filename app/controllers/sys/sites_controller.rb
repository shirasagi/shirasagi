class Sys::SitesController < ApplicationController
  include Sys::BaseFilter
  include Sys::CrudFilter

  model Sys::Site

  menu_view "sys/crud/menu"

  before_action :check_permissions
  before_action :set_search_param
  after_action :reload_nginx, only: [:create, :update, :destroy, :destroy_all]

  private

  def check_permissions
    raise "403" unless @cur_user.sys_role_permit_any?(:edit_sys_sites)
  end

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
    @items = @model.allow(:read, @cur_user).
      state(params.dig(:s, :state)).
      search(@s).
      order_by(_id: -1)
  end

  def show
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
  end

  def create
    @item = @model.new get_params
    result = @item.save

    if result
      cond = {
        site_id: @item.id,
        name: I18n.t('cms.roles.admin'),
        permissions: Cms::Role.permission_names,
      }
      role = Cms::Role.find_or_create_by cond

      cms_user = Cms::User.find(@cur_user.id)
      cms_user.add_to_set cms_role_ids: role.id
    end

    render_create result
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    render_update @item.update
  end

  def delete
    render
  end

  def destroy
    render_destroy @item.disable
  end

  def destroy_all
    disable_all
  end
end
