class Webmail::HistoriesController < ApplicationController
  include Webmail::BaseFilter
  include Sys::CrudFilter

  model Webmail::History

  before_action :set_ymd

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.webmail/history"), action: :index]
  end

  def set_ymd
    if params[:ymd].blank?
      redirect_to webmail_daily_histories_path(ymd: Time.zone.now.strftime('%Y%m%d'))
      return
    end

    @s = OpenStruct.new(params[:s])
    @s.ymd = params[:ymd]
  end

  def set_items
    @items = @model.all.search(@s)
  end

  public

  def index
    raise '403' unless Webmail::History.allowed?(:read, @cur_user)

    set_items
    @items = @items.page(params[:page]).per(50)
  end

  def download
    raise '403' unless Webmail::History.allowed?(:read, @cur_user)

    set_items
    return if request.get? || request.head?

    filename = 'webmail_histories'
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum Webmail::History::Csv.enum_csv(@items), type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
