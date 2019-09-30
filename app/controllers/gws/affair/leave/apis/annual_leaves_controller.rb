class Gws::Affair::Leave::Apis::AnnualLeavesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::LeaveSetting

  def index
    @start_at = Time.zone.parse(params[:year_month_day])
    @user = Gws::User.active.find_by(id: params[:uid])
    @minutes = @model.effective_annual_leave_minutes(@cur_site, @user, @start_at)
    render layout: false
  end
end
