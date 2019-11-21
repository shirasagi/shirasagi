class Opendata::Dataset::AccessReportsController < ApplicationController
  include Cms::BaseFilter

  model Opendata::DatasetAccessReport

  navi_view "opendata/main/navi"

  before_action :set_item

  private

  def set_crumbs
    @crumbs << [t("opendata.reports.report"), opendata_dataset_report_main_path]
    @crumbs << [t("opendata.reports.access_reports"), { action: :index }]
  end

  def set_item
    if params[:item]
      attributes = params[:item].to_unsafe_h
    else
      attributes = {}
    end

    attributes.merge!(
      cur_node: @cur_node,
      cur_site: @cur_site,
      cur_user: @cur_user
    )
    @item = @model.new(attributes)
  end

  public

  def index
    @item.type ||= "day"
    @aggregate = @item.aggregate
  end

  def download
    return render :index unless @item.valid?
    send_enum @item.enum_csv, type: 'text/csv; charset=Shift_JIS',
      filename: "dataset_access_report_#{Time.zone.now.to_i}.csv"
  end
end
