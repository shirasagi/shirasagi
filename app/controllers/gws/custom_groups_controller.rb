class Gws::CustomGroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::CustomGroup

  navi_view "gws/main/conf_navi"

  before_action :set_default_readable_setting, only: [:new]

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.gws/custom_group"), gws_custom_groups_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_default_readable_setting
    @default_readable_setting = proc do
      @item.readable_setting_range = "public"
    end
  end

  public

  def index
    @search_params = params[:s].presence

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)

    if @search_params
      @items = @items.search(@search_params).page(params[:page]).per(50)
    else
      @items = @items.tree_sort
    end
  end

  def download_all
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @model = SS::DownloadParam

    if request.get? || request.head?
      @item = SS::DownloadParam.new
      render
      return
    end

    @item = SS::DownloadParam.new params.require(:item).permit(:encoding)
    if @item.invalid?
      render
      return
    end

    csv = Gws::CustomGroup.unscoped.site(@cur_site).order_by(_id: 1).to_csv
    case @item.encoding
    when "Shift_JIS"
      csv = csv.encode("SJIS", invalid: :replace, undef: :replace)
    when "UTF-8"
      csv = SS::Csv::UTF8_BOM + csv
    end

    send_data csv, filename: "gws_custom_groups_#{Time.zone.now.to_i}.csv"
  end

  def import
    return if request.get? || request.head?

    @item = @model.new get_params
    @item.cur_site = @cur_site
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { action: :import }
  end
end
