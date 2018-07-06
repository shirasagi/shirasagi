class Gws::Presence::Management::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::User

  menu_view "gws/presence/management/users/menu"
  navi_view "gws/presence/main/navi"

  before_action :deny_with_auth

  private

  def deny_with_auth
    raise "403" unless Gws::Presence::UserPresence.other_permission?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_management_users_path]
  end

  def set_group
    @groups = [@cur_site.root.to_a, @cur_site.root.descendants.to_a].flatten
    @custom_groups = Gws::CustomGroup.site(@cur_site).in(member_ids: @cur_user.id)
  end

  def set_item
    @user = @model.find(params[:id])
    @item = @user.user_presence(@cur_site)
    @item ||= Gws::Presence::UserPresence.new(fix_params)
  end

  def fix_params
    { cur_user: @user, cur_site: @cur_site }
  end

  def permit_fields
    Gws::Presence::UserPresence.permitted_fields
  end

  public

  def index
    @items = @model.in(group_ids: @groups.pluck(:id)).
      search(params[:s]).page(params[:page]).per(25)
  end

  def edit
    render
  end

  def update
    @item.attributes = get_params
    render_update @item.save, location: { action: :index }
  end
end
