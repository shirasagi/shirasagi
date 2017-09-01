class Gws::StaffRecord::PublicRecordsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::PublicYearlyFilter

  model Gws::StaffRecord::User

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.staff_records"), action: :index]
  end

  public

  def index
    @limit = params.dig(:s, :limit).presence || @cur_site.staff_records_limit

    @items = @cur_year.yearly_users.show_staff_records.
      search(params[:s]).
      page(params[:page]).
      per(@limit)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    @items = @cur_year.yearly_users.show_staff_records.
      where(section_name: @item.section_name).
      where(charge_name: @item.charge_name).
      all
  end
end
