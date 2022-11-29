class Gws::Affair::Overtime::Management::Aggregate::SearchGroupsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  helper Gws::Affair::TimeHelper

  navi_view "gws/affair/main/navi"

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [
      t("modules.gws/affair/overtime_file/management/aggregate"),
      gws_affair_overtime_management_aggregate_search_groups_main_path]
    @crumbs << [
      t("modules.gws/affair/overtime_file/management/aggregate/search_groups"),
      gws_affair_overtime_management_aggregate_search_groups_main_path]
  end

  def set_query
    @group_ids = params.dig(:s, :group_ids).to_a.select(&:present?).map(&:to_i)

    @s = OpenStruct.new
    @s[:group_ids] = @group_ids
  end

  def set_items
    @groups = @result_groups.select { |group| @group_ids.include?(group.group_id) }
    @title = I18n.t("gws/affair.labels.overtime.search.title", year: @fiscal_year, month: @month)
    @items, = @model.site(@cur_site).where(date_fiscal_year: @fiscal_year, date_month: @month).capital_aggregate_by_group
  end

  public

  def index
    redirect_to({ action: :search, fiscal_year: @cur_fiscal_year, month: @cur_month })
  end

  def search
    set_result_groups
    @groups = @result_groups.select { |group| @group_ids.include?(group.group_id) }
  end

  def results
    set_capitals
    set_result_groups
    set_items
    @download_url = url_for({ action: :download, s: @s.to_h }) if @groups.present?
  end

  def download
    return if request.get? || request.head?

    results
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::Capital::Groups.new(
      @items, @capitals, @groups,
      title: @title,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end
end
