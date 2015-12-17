class Gws::Schedule::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_facility

  private
    def set_facility
      @facility = Gws::Facility.site(@cur_site).find(params[:facility])
    end

    def pre_params
      super.merge facility_ids: [@facility.id]
    end

  public
    def index
      @items = Gws::Schedule::Plan.site(@cur_site).
        facility(@facility).
        #allow(:read, @cur_user, site: @cur_site).
        search(params[:s])
    end
end
