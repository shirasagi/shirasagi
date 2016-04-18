class Gws::GroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Group

  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/group", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

    def set_item
      super
      raise "403" unless Gws::Group.site(@cur_site).include?(@item)
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        state(params.dig(:s, :state)).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).sort_by(&:name)
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
      render_destroy @item.disable
    end

    def destroy_all
      disable_all
    end
end
