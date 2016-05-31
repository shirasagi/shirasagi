class Gws::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::User

  prepend_view_path "app/views/sys/users"
  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/user", gws_users_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def group_ids
      if params[:s].present? && params[:s][:group].present?
        @group = @cur_site.descendants.active.find(params[:s][:group]) rescue nil
      end
      @group ||= @cur_site
      @group_ids ||= @cur_site.descendants.active.in_group(@group).pluck(:id)
    end

  public
    def index
      @groups = @cur_site.descendants.active

      @items = @model.site(@cur_site).
        state(params.dig(:s, :state)).
        allow(:read, @cur_user, site: @cur_site).
        in(group_ids: group_ids).
        search(params[:s]).
        order_by_title(@cur_site).
        page(params[:page]).per(50)
    end

    def update
      other_group_ids = Gws::Group.nin(id: Gws::Group.site(@cur_site).pluck(:id)).in(id: @item.group_ids).pluck(:id)
      other_role_ids = Gws::Role.nin(id: Gws::Role.site(@cur_site).pluck(:id)).in(id: @item.gws_role_ids).pluck(:id)

      @item.attributes = get_params
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      @item.update

      @item.add_to_set(group_ids: other_group_ids)
      @item.add_to_set(gws_role_ids: other_role_ids)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
      render_update @item.update
    end


    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
      render_destroy @item.disable
    end

    def destroy_all
      disable_all
    end
end
