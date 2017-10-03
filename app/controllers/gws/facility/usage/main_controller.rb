class Gws::Facility::Usage::MainController < ApplicationController
  def index
    last_month = Time.zone.now.beginning_of_month.last_month
    redirect_to gws_facility_usage_monthly_index_path(yyyymm: last_month.strftime('%Y%m'))
  end
end
