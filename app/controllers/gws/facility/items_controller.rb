class Gws::Facility::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Item

  navi_view "gws/facility/settings/navi"

  private
    def set_crumbs
      @crumbs << [:"modules.settings.gws/facility", gws_facility_items_path]
      @crumbs << [:"modules.settings.gws/facility/item", gws_facility_items_path]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
