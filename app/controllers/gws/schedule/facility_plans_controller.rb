class Gws::Schedule::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_facility
  before_action :set_download_url, only: :index

  navi_view "gws/schedule/main/navi"

  private

  def set_facility
    @facility ||= Gws::Facility::Item.site(@cur_site).find(params[:facility])
    raise '403' unless @facility.readable?(@cur_user)
  end

  def pre_params
    super.merge facility_ids: [@facility.id]
  end

  def set_download_url
    @download_url = url_for(action: :download)
  end

  def set_items
    set_facility
    @items ||= Gws::Schedule::Plan.site(@cur_site).without_deleted.
      facility(@facility).
      search(params[:s])
  end

  public

  def events
    render json: @items.map { |m| m.facility_calendar_format(@cur_user, @cur_site) }.to_json
  end

  def download
    filename = "gws_schedule_facility_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site, user: @cur_user),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end
end
