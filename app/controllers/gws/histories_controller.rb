class Gws::HistoriesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::History

  navi_view 'gws/histories/navi'

  before_action :set_ymd
  helper_method :today, :origin, :next_day, :prev_day

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/history"), action: :index]
  end

  def set_ymd
    if params[:ymd].blank?
      redirect_to gws_daily_histories_path(ymd: "-")
      return
    end

    ymd = params[:ymd].to_s

    @s = OpenStruct.new(params[:s])
    @s.ymd = ymd if ymd != "-"
  end

  def set_items
    @items = @model.site(@cur_site).search(@s)
  end

  def today
    @today ||= Time.zone.today
  end

  def origin
    return @origin if instance_variable_defined?(:@origin)

    @origin = begin
      ymd = params[:ymd].to_s if params[:ymd].present?
      if ymd
        year = ymd[0..3]
        month = ymd[4..5]
        day = ymd[6..7]
      end

      if year.numeric? && month.numeric? && day.numeric?
        Time.zone.local(ymd[0..3].to_i, ymd[4..5].to_i, ymd[6..7].to_i)
      end
    end
  end

  def next_day
    @next_day ||= (origin || today) + 1.day
  end

  def prev_day
    @prev_day ||= (origin || today) - 1.day
  end

  public

  def index
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    @items = @items.page(params[:page]).per(50)
  end

  def download
    raise '403' unless Gws::History.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    if request.get? || request.head?
      @item = Gws::HistoryDownloadParam.new
      @item.to = Time.zone.today
      @item.from = Time.zone.today
      return
    end

    csv_params = Gws::HistoryDownloadParam.new params.require(:item).permit(:encoding, :from, :to)
    if csv_params.invalid?
      @item = csv_params
      render
      return
    end

    @items = @items.gte(created: csv_params.from.beginning_of_day) if csv_params.from
    @items = @items.lt(created: (csv_params.to + 1.day).beginning_of_day) if csv_params.to

    exporter = Gws::HistoryCsv.new(site: @cur_site, criteria: @items)
    enumerable = exporter.enum_csv(encoding: csv_params.encoding)

    filename = @model.to_s.tableize.tr("/", "_")
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end
end
