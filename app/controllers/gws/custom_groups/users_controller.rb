class Gws::CustomGroups::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::CustomGroupUser

  navi_view "gws/main/conf_navi"

  before_action :set_custom_group

  private
    def set_crumbs
      set_custom_group
      @crumbs << [:"mongoid.models.gws/custom_group", gws_custom_groups_path]
      @crumbs << [@custom_group.name, gws_custom_group_users_path]
      #@crumbs << [:"mongoid.models.gws/user", gws_custom_group_users_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, custom_group_id: params[:custom_group_id] }
    end

    def set_custom_group
      @custom_group ||= Gws::CustomGroup.find params[:custom_group_id]
      raise "403" unless @custom_group.allowed?(:read, @cur_user, site: @cur_site)
    end

  public
    def index
      @items = @model.site(@cur_site).
        where(custom_group_id: @custom_group).
        search(params[:s]).
        order_by(order: 1).
        page(params[:page]).per(50)
    end
end
