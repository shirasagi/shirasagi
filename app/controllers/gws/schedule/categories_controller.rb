class Gws::Schedule::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/main/conf_navi"

  model Gws::Schedule::Category

  private
    def set_crumbs
      @crumbs << [:"modules.gws/schedule.", gws_schedule_plans_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(_id: -1).
        page(params[:page]).per(50)
    end
end
