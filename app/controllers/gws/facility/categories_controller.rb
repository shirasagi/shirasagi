class Gws::Facility::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Category

  navi_view "gws/facility/settings/navi"

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/facility", gws_facility_items_path]
      @crumbs << [:"modules.settings.gws/facility/category", gws_facility_categories_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
