class Cms::CheckLinks::NodesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::CheckLinks::Error::Node

  before_action :set_report
  before_action :set_items, only: [:index, :download]

  prepend_view_path "app/views/cms/check_links/pages"

  private

  def set_report
    @cur_report = Cms::CheckLinks::Report.site(@cur_site).find(params[:report_id])
  end

  def set_items
    @items = @model.site(@cur_site).and_report(@cur_report).
      allow(:read, @cur_user, site: @cur_site).
      order_by(filename: 1)
  end

  def set_item
    super
    @content = @item.content
  end

  public

  def index
    @items = @items.search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    send_enum @items.enum_csv, type: 'text/csv; charset=Shift_JIS', filename: "#{@cur_report.name}_#{Time.zone.now.to_i}.csv"
  end
end
