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

  public
    def index
      state = params.dig(:s, :state) || 'enabled'

      @items = @model.site(@cur_site).
        state(state).
        allow(:read, @cur_user, site: @cur_site).
        page(params[:page]).per(50)
    end
end
