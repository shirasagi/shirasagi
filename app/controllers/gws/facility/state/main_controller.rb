class Gws::Facility::State::MainController < ApplicationController
  def index
    last_month = Time.zone.now.beginning_of_month.last_month
    redirect_to gws_facility_state_daily_index_path(yyyymmdd: Time.zone.today.strftime('%Y%m%d'))
  end
end
