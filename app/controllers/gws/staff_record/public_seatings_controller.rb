class Gws::StaffRecord::PublicSeatingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::PublicYearlyFilter

  model Gws::StaffRecord::Seating

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.staff_records"), gws_staff_record_public_records_path]
    @crumbs << [t("mongoid.models.gws/staff_record/seating"), action: :index]
  end

  public

  def index
    @items = @cur_year.yearly_seatings.
      readable(@cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page])
  end
end
