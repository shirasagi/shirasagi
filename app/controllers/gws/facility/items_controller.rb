class Gws::Facility::ItemsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Item

  navi_view "gws/facility/main/navi"

  private
    def set_crumbs
      @crumbs << [:"mongoid.models.gws/facility/item", action: :index]
    end

    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end
end
