class Gws::Affair::CapitalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Affair::Capital

  navi_view "gws/affair/main/navi"

  before_action :set_year

  private

  def set_crumbs
    set_year
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [@cur_year.name, gws_affair_capital_years_path]
    @crumbs << [t('modules.gws/affair/capital'), gws_affair_capitals_path]
  end

  def set_year
    @cur_year ||= Gws::Affair::CapitalYear.site(@cur_site).find(params[:year])
  end

  def pre_params
    { cur_user: @cur_user, cur_site: @cur_site, year: @cur_year }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, year: @cur_year }
  end

  def set_items
    @items = @cur_year.yearly_capitals
  end

  public

  def index
    set_items
    @items = @items.allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end

  def download
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @model.in(id: @items.pluck(:id)).to_csv
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: "gws_affair_capitals_#{Time.zone.now.to_i}.csv"
  end

  def import
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?
    @item = @model.new get_params
    result = @item.import
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :index }, render: { file: :import }
  end

  def import_member
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?
    @item = @model.new get_params
    result = @item.import_member
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :import_member }, render: { file: :import_member }
  end

  def download_member
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @model.in(id: @items.pluck(:id)).member_to_csv(@cur_site)
    filename = "gws_affair_capital_members_#{Time.zone.now.to_i}.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  def import_group
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    return if request.get? || request.head?
    @item = @model.new get_params
    result = @item.import_group
    flash.now[:notice] = t("ss.notice.saved") if !result && @item.imported > 0
    render_create result, location: { action: :import_group }, render: { file: :import_group }
  end

  def download_group
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    set_items
    csv = @model.in(id: @items.pluck(:id)).group_to_csv(@cur_site)
    filename = "gws_affair_capital_groups_#{Time.zone.now.to_i}.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end
end
