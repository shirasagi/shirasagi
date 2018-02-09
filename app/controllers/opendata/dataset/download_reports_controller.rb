class Opendata::Dataset::DownloadReportsController < ApplicationController
  include Cms::BaseFilter

  model Opendata::DownloadReport

  navi_view "opendata/main/navi"

  before_action :set_item

  private

  def set_item
    @item = @model.new(params[:item])
  end

  public

  def index
  end

  def download
    render :index unless @item.valid?
  end
end
