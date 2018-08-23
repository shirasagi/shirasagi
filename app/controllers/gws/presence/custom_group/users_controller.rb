class Gws::Presence::CustomGroup::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::UserFilter

  prepend_view_path "app/views/gws/presence/users"

  private

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_users_path]
    @crumbs << [@custom_group.name, gws_presence_custom_group_users_path(group: @custom_group.id)]
  end

  def set_group
    @custom_group = Gws::CustomGroup.site(@cur_site).find(params[:group])
    raise "404" unless @custom_group.member_ids.include?(@cur_user.id)

    @groups = @cur_site.root.to_a + @cur_site.root.descendants.to_a
    @custom_groups = Gws::CustomGroup.site(@cur_site).in(member_ids: @cur_user.id)
  end

  def items
    @items = @custom_group.members.search(params[:s]).page(params[:page]).per(25)
  end

  public

  def index
    items
    @table_url = table_gws_presence_custom_group_users_path(site: @cur_site, group: @custom_group)
    @paginate_params = { controller: 'gws/presence/custom_group/users', action: 'index' }
  end

  def table
    items
    render file: :table, layout: false
  end

  def portlet
    items
    @manageable_users, @group_users = @items.partition { |item| @editable_user_ids.include?(item.id) }
    render file: :portlet, layout: false
  end
end
