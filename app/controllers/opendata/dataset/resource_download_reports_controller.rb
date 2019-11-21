class Opendata::Dataset::ResourceDownloadReportsController < ApplicationController
  include Cms::BaseFilter

  model Opendata::ResourceDownloadReport

  navi_view "opendata/main/navi"
  menu_view nil

  before_action :set_search_params
  before_action :set_items

  private

  def set_crumbs
    @crumbs << [t("opendata.reports.report"), opendata_dataset_report_main_path]
    @crumbs << [t("opendata.reports.download_reports"), { action: :index }]
  end

  def set_search_params
    @s ||= begin
      now = Time.zone.now
      s = OpenStruct.new(params[:s])
      s.cur_site = @cur_site
      s.start_year ||= now.year
      s.start_month ||= now.month
      s.end_year ||= now.year
      s.end_month ||= now.month
      s.type ||= "day"
      s
    end
  end

  def set_items
    case @s.type
    when "month"
      @items ||= @model.site(@cur_site).search(@s).aggregate_by_month
    when "year"
      @items ||= @model.site(@cur_site).search(@s).aggregate_by_year
    else
      @items ||= @model.site(@cur_site).search(@s).order_by(site_id: 1, year_month: 1, dataset_id: 1, resource_id: 1)
    end
  end

  public

  def index
    @items = Kaminari.paginate_array(@items) if @items.is_a?(Array)
    @items = @items.page(params[:page]).per(50)
  end

  def download
    enum = begin
      case @s.type
      when "month"
        @model.enum_monthly_csv(@cur_site, @cur_node, @items)
      when "year"
        @model.enum_yearly_csv(@cur_site, @cur_node, @items)
      else
        @items.enum_csv(@cur_site, @cur_node)
      end
    end

    send_enum enum, type: 'text/csv; charset=Shift_JIS',
              filename: "dataset_download_report_#{Time.zone.now.to_i}.csv"
  end
end
