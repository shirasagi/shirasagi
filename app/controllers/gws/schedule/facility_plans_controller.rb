class Gws::Schedule::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  before_action :set_facility

  private
    def set_facility
      @facility = Gws::Facility::Item.site(@cur_site).find(params[:facility])
      raise '403' unless @facility.readable?(@cur_user)
    end

    def pre_params
      super.merge facility_ids: [@facility.id]
    end

  public
    def events
      @items = Gws::Schedule::Plan.site(@cur_site).
        facility(@facility).
        search(params[:s])

      render json: @items.map { |m| m.facility_calendar_format(@cur_user, @cur_site) }.to_json
    end
end
