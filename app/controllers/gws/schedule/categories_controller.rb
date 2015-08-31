class Gws::Schedule::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/schedule/main/navi"

  model Gws::Schedule::Category

  private
    def set_crumbs
      @crumbs << [:"modules.gws_schedule.", gws_schedule_calendars_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
