class Gws::Presence::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::User

  menu_view "gws/presence/main/menu"
  navi_view "gws/presence/main/navi"

  before_action :deny_with_auth
  before_action :set_editable_users

  private

  def deny_with_auth
    raise "403" unless Gws::UserPresence.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_users_path]
  end

  def set_group
    @groups = [@cur_site.root.to_a, @cur_site.root.descendants.to_a].flatten
    @custom_groups = Gws::CustomGroup.site(@cur_site).in(member_ids: @cur_user.id)
  end

  def set_editable_users
    @editable_users = @cur_user.presence_editable_users(@cur_site)
    @editable_user_ids = @editable_users.map(&:id)
  end

  def items
    @items = @model.in(group_ids: @groups.pluck(:id)).
      search(params[:s]).page(params[:page]).per(25)
  end

  public

  def index
    @table_url = table_gws_presence_users_path(site: @cur_site)
    items
  end

  def table
    items
    render layout: false
  end
end
