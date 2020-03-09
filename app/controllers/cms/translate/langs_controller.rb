class Cms::Translate::LangsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model ::Translate::Lang
  navi_view "cms/translate/main/navi"

  private

  def fix_params
    { cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    set_items
    @items = @items.search(params[:s])
      .page(params[:page]).per(100)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
    set_items
    filename = @model.to_s.tableize.gsub(/\//, "_")
    send_enum @items.enum_csv, filename: "#{filename}_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @model.new
    return if request.get?

    @item.attributes = get_params
    result = @item.import_csv
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
