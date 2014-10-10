class Cms::UsersController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::User

  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.user", action: :index]
    end

    def set_item
      super
      raise "403" unless Cms::User.site(@cur_site).include?(@item)
    end

  public
    def index
      raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

      @items = @model.site(@cur_site).
        allow(:edit, @cur_user, site: @cur_site).
        order_by(name: 1).
        page(params[:page]).per(50)
    end

    def update
      other_group_ids = Cms::Group.nin(id: Cms::Group.site(@cur_site).pluck(:id)).in(id: @item.group_ids).pluck(:id)
      other_role_ids = Cms::Role.nin(id: Cms::Role.site(@cur_site).pluck(:id)).in(id: @item.cms_role_ids).pluck(:id)

      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      @item.update

      @item.add_to_set(group_ids: other_group_ids)
      @item.add_to_set(cms_role_ids: other_role_ids)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_update @item.update
    end
end
