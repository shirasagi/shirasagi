class Gws::StaffRecord::SeatingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::StaffRecord::SettingFilter

  model Gws::StaffRecord::Seating

  navi_view "gws/main/navi"

  before_action :set_year

  private

  def set_crumbs
    set_year
    @crumbs << ["#{@cur_year.name} " + t("mongoid.models.gws/staff_record/seating"), gws_staff_record_seatings_path]
  end

  public

  def index
    @items = @cur_year.yearly_seatings.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    items = @cur_year.yearly_seatings.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)

    @item = @model.new(fix_params)
    send_data @item.export_csv(items), filename: "staff_record_#{@cur_year.code}_seatings_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    @item = @model.new(get_params)
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { template: "import" }
  end
end
