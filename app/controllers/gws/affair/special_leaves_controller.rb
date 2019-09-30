class Gws::Affair::SpecialLeavesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::SpecialLeave

  navi_view "gws/affair/main/navi"
  menu_view "gws/affair/main/menu"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/special_leave'), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      order_by(id: 1)
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @tabs = SS.config.gws.user["staff_category"] || []
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(order: 1)

    if params[:staff_category].present?
      @items = @items.where(staff_category: params[:staff_category])
    end
    @items = @items.page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @items.to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_affair_special_leaves_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
