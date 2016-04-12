class Gws::Schedule::HolidaysController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  helper Gws::Schedule::PlanHelper

  navi_view "gws/schedule/settings/navi"

  model Gws::Schedule::Holiday

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/schedule", gws_schedule_setting_path]
      @crumbs << [:"modules.settings.gws/schedule/holiday", gws_schedule_plans_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        order_by(start_at: -1).
        page(params[:page]).per(50)
    end
end
