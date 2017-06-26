class Jmaxml::WaterLevelStationsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Jmaxml::WaterLevelStation

  navi_view "rss/main/navi"

  private

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(order: 1).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    set_items
    @items = @items.order_by(order: 1, id: 1)

    filename = "water_level_stations_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum SS::CsvConverter.enum_csv(@items, %w(code name region_name order state)),
              type: 'text/csv; charset=Shift_JIS', filename: filename
  end

  def import
    @item = OpenStruct.new
    if request.get?
      render file: 'rss/main/import'
      return
    end

    file = params.require(:item).permit(:in_file)[:in_file]
    temp_file = SS::TempFile.new
    temp_file.in_file = file
    temp_file.save!

    job_class = Jmaxml::WaterLevelStationImportJob
    job_class.bind(site_id: @cur_site, user_id: @cur_user).perform_later(temp_file.id)

    redirect_to({ action: :index }, { notice: I18n.t('ss.notice.started_import') })
  end
end
