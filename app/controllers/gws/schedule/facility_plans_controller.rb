class Gws::Schedule::FacilityPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter
  include Gws::Memo::NotificationFilter

  before_action :set_facility
  before_action :set_download_url, only: :index
  before_action :set_default_readable_setting, only: [:new]

  navi_view "gws/schedule/main/navi"

  private

  def set_facility
    @facility ||= Gws::Facility::Item.site(@cur_site).find(params[:facility])
    raise '403' unless @facility.readable?(@cur_user)
  end

  def pre_params
    h = super
    h[:facility_ids] = [@facility.id]

    member_ids = h[:member_ids].to_a
    member_ids += @facility.default_member_ids
    member_ids.uniq!

    h[:member_ids] = member_ids
    h
  end

  def set_download_url
    @download_url = url_for(action: :download)
  end

  def set_items
    set_facility
    @items ||= Gws::Schedule::Plan.site(@cur_site).without_deleted.
      facility(@facility).
      search(@search_plan)
  end

  public

  def events
    @events = @items.map { |m| m.calendar_format(@cur_user, @cur_site) }
  end

  def download
    filename = "gws_schedule_facility_plans_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum(
      Gws::Schedule::PlanCsv::Exporter.enum_csv(@items, site: @cur_site, user: @cur_user),
      type: 'text/csv; charset=Shift_JIS', filename: filename
    )
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def set_default_readable_setting
    @default_readable_setting = proc do
      @item.readable_setting_range = @facility.readable_setting_range
      @item.readable_group_ids = @facility.readable_group_ids
      @item.readable_member_ids = @facility.readable_member_ids
      @item.readable_custom_group_ids = @facility.readable_custom_group_ids
    end
  end
end
