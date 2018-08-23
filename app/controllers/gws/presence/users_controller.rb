class Gws::Presence::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::UserFilter

  private

  def set_crumbs
    set_group
    @crumbs << [t("modules.gws/presence"), gws_presence_users_path]
  end

  def set_group
    @groups = @cur_site.root.to_a + @cur_site.root.descendants.to_a
    @custom_groups = Gws::CustomGroup.site(@cur_site).in(member_ids: @cur_user.id)
  end

  def items
    @items = @model.in(group_ids: @groups.pluck(:id)).
      search(params[:s]).page(params[:page]).per(25)
  end

  public

  def index
    items
    @table_url = table_gws_presence_users_path(site: @cur_site)
    @paginate_params = { controller: 'gws/presence/users', action: 'index' }
  end

  def table
    items
    render file: :table, layout: false
  end
end
