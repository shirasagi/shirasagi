class Gws::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility

  navi_view "gws/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/facility", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
