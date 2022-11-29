class Gws::Affair::SpecialLeavesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter

  model Gws::Affair::SpecialLeave

  navi_view "gws/affair/main/navi"
  menu_view "gws/affair/main/menu"

  before_action :set_staff_category

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

  def set_staff_category
    @staff_category_options = @model.new.staff_category_options
    @staff_category = params[:staff_category]
  end

  public

  def index
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(order: 1)

    if @staff_category_options.map { |_, k| k.to_s }.include?(@staff_category)
      @items = @items.where(staff_category: @staff_category)
    end
    @items = @items.page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @items.to_csv
    filename = "gws_affair_special_leaves_#{Time.zone.now.to_i}.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?
    @item = @model.new get_params
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end
end
