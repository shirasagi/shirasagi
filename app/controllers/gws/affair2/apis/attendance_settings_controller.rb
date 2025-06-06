class Gws::Affair2::Apis::AttendanceSettingsController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair2::AttendanceSetting

  def index
    @single = params[:single].present?
    @multi = !@single

    @fiscal_year = params[:fiscal_year].to_i
    start_date = @cur_site.fiscal_first_date(@fiscal_year)
    close_date = @cur_site.fiscal_last_date(@fiscal_year)

    @items = @model.site(@cur_site).
      and_between(start_date, close_date).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
