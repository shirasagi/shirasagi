class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  def index
    @items = Gws::Facility.site(@cur_site).
      order_by(name: 1)
  end

  def events
    @items = Gws::Schedule::Plan.site(@cur_site).
      exists(facility_ids: true).
      search(params[:s])
  end
end
