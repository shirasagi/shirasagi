class Gws::Presence::Group::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::UserFilter

  prepend_view_path "app/views/gws/presence/users"

  private

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_users_path]
    @crumbs << [@group.trailing_name, gws_presence_group_users_path(group: @group.id)]
  end

  def set_group
    @group = Gws::Group.find(params[:group])
    raise "404" unless @group.name.start_with?(@cur_site.name)

    @custom_groups = Gws::CustomGroup.site(@cur_site).member(@cur_user)
  end

  def items
    @items = @group.users.active.search(params[:s]).order_by_title(@cur_site).
      page(params[:page]).per(25)
  end

  public

  def index
    items
    @table_url = table_gws_presence_group_users_path(site: @cur_site, group: @group)
    @paginate_params = { controller: 'gws/presence/group/users', action: 'index' }
  end

  def table
    items
    render template: "table", layout: false
  end

  def portlet
    @items = @group.users.active.search(params[:s]).order_by_title(@cur_site)
    @manageable_users, @group_users = @items.partition { |item| @editable_user_ids.include?(item.id) }
    render template: "portlet", layout: false
  end
end
