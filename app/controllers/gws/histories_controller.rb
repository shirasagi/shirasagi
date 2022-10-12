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
    return if request.get? || request.head?

    filename = 'gws_histories'
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum Gws::HistoryCsv.enum_csv(@cur_site, @items), type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
