class Gws::Schedule::MainController < ApplicationController
  include Gws::BaseFilter

  def index
    if Gws::Schedule::Plan.allowed?(:use, @cur_user, site: @cur_site)
      redirect_to gws_schedule_plans_path
      return
    end

    if @cur_user.gws_role_permit_any?(@cur_site, :use_private_gws_facility_plans)
      redirect_to gws_schedule_facilities_path
      return
    end

    raise "404"
  end
end
