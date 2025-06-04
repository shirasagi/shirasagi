class Gws::Affair2::Management::AggregationMainController < ApplicationController
  include Gws::BaseFilter

  def index
    @employee_type = params[:employee_type] || "regular"
    @unit = "monthly"
    @form = "works"
    @year_month = @cur_site.affair2_attendance_date.strftime('%Y%m')
    redirect_to gws_affair2_management_aggregations_path(unit: @unit, employee_type: @employee_type,
      form: @form, year_month: @year_month)
  end
end
