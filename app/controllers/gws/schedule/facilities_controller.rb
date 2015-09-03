class Gws::Schedule::FacilitiesController < ApplicationController
  include Gws::BaseFilter
  #include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  public
    def index
      @items = Gws::Facility.site(@cur_site).
        order_by(name: 1)
    end
end
