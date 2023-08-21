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
    set_search_params
    @limit = @s[:limit].presence || @cur_site.staff_records_limit
    @items = @cur_year.yearly_users.show_staff_records.
      readable(@cur_user, site: @cur_site).
      search(@s).
      order_by_title(@cur_site).
      page(params[:page]).
      per(@limit)
  end

  def show
    raise "403" unless @item.readable?(@cur_user)

    @items = @cur_year.yearly_users.show_staff_records.
      readable(@cur_user, site: @cur_site).
      where(section_name: @item.section_name).
      where(charge_name: @item.charge_name).
      order_by_title(@cur_site)
  end
end
