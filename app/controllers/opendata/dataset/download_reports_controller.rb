class Opendata::Dataset::DownloadReportsController < ApplicationController
  include Cms::BaseFilter

  model Opendata::DatasetDownloadReport

  navi_view "opendata/main/navi"

  before_action :set_item

  private

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
  end

  def download
    return render :index unless @item.valid?
    send_data @item.csv.encode("SJIS", invalid: :replace, undef: :replace),
      filename: "dataset_download_report_#{Time.zone.now.to_i}.csv"
  end
end
