class Gws::StaffRecord::PublicDutiesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::PublicYearlyFilter

  model Gws::StaffRecord::User

  private

  def set_crumbs
    @crumbs << [t("gws/staff_record.divide_duties"), action: :index]
  end

  public

  def index
    @limit = params.dig(:s, :limit).presence || @cur_site.divide_duties_limit

    @items = @cur_year.yearly_users.show_divide_duties.
      search(params[:s]).
      page(params[:page]).
      per(@limit)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    @items = @cur_year.yearly_users.show_divide_duties.
      where(section_code: @item.section_code).
      where(charge_name: @item.charge_name).
      all
  end
end
