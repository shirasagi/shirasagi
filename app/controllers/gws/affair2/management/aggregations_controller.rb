class Gws::Affair2::Management::AggregationsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair2::BaseFilter
  include Gws::Affair2::YearMonthFilter

  navi_view "gws/affair2/management/main/navi"

  helper_method :default_year_month, :employee_type_options, :leave_type_options

  before_action :set_unit
  before_action :set_form

  #model Gws::Affair2::Aggregation::Month

  def set_unit
    if params[:unit] == "daily"
      @unit = "daily"
      @model = Gws::Affair2::Aggregation::Day
    else
      @unit = "monthly"
      @model = Gws::Affair2::Aggregation::Month
    end
  end

  def set_form
    if params[:form] == "leave"
      @form = "leave"
      @downloader_model = Gws::Affair2::Aggregation::Downloader::Leave
    else
      @form = "works"
      @downloader_model = Gws::Affair2::Aggregation::Downloader::Works
    end
  end

  def default_year_month
    @default_year_month ||= @attendance_date.strftime('%Y%m')
  end

  def employee_type_options
    I18n.t("gws/affair2.options.employee_type").map { |k, v| [v, k] }
  end

  def leave_type_options
    Gws::Affair2::LeaveSetting.leave_type_options
  end

  def items
    @model.site(@cur_site).and_viewable(month: @cur_month, employee_type: params[:employee_type], form: @form)
  end

  def index
    @s = { keyword: params[:keyword ]}
    @items = items.search(@s).
      page(params[:page]).
      per(50)
  end

  def download
    @item = SS::DownloadParam.new
    if request.get? || request.head?
      render
      return
    end

    @item.attributes = params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    downloader = @downloader_model.new(items, unit: @unit)
    send_enum downloader.enum_csv(encoding: @item.encoding),
      filename: "aggregation_monthly_#{Time.zone.now.to_i}.csv"
  end
end
