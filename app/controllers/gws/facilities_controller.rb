class Gws::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
