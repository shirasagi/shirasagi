class Gws::Facility::CategoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Category

  navi_view "gws/facility/settings/navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/facility/group_setting", gws_facility_items_path]
      @crumbs << [:"mongoid.models.gws/facility/group_setting/category", gws_facility_categories_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
