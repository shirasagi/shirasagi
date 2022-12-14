class Gws::Affair::Overtime::Aggregate::CapitalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  helper Gws::Affair::TimeHelper

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime/aggregate"), gws_affair_overtime_aggregate_main_path]
    @crumbs << [t("modules.gws/affair/overtime/aggregate/capital"), gws_affair_overtime_aggregate_capitals_main_path]
  end

  public

  def index
    redirect_to({ action: :yearly, fiscal_year: @cur_fiscal_year })
  end

  def yearly
    set_capitals
    set_result_groups

    @group = @result_groups.find_group(@cur_site.id)
    @months = (4..12).to_a + (1..3).to_a

    @title = I18n.t("gws/affair.labels.overtime.capitals.title", year: @fiscal_year)
    @items, = @model.site(@cur_site).where(date_fiscal_year: @fiscal_year).capital_aggregate_by_month
  end

  def groups
    set_capitals
    set_result_groups

    @group = @result_groups.find_group(params[:group].to_i)
    if @group
      @parent = @group.parent
      @users = @group.users
      @children = @group.children.presence || [@group]
    else
      @parent = nil
      @users = []
      @children = []
    end

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_groups", year: @fiscal_year, month: @month, group: @group.name)
    @items, = @model.site(@cur_site).where(date_fiscal_year: @fiscal_year, date_month: @month).capital_aggregate_by_group
  end

  def users
    set_capitals
    set_result_groups

    @group = @result_groups.find_group(params[:group].to_i)
    if @group
      @parent = @group.parent
      @users = @group.users
    else
      @parent = nil
      @users = []
    end

    @title = I18n.t("gws/affair.labels.overtime.capitals.title_users", year: @fiscal_year, month: @month, group: @group.name)
    @items, = @model.site(@cur_site).where(date_fiscal_year: @fiscal_year, date_month: @month).capital_aggregate_by_group_users
  end

  def download_yearly
    if request.get? || request.head?
      render :download
      return
    end

    yearly
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::Capital::Yearly.new(
      @items, @capitals, @fiscal_year,
      title: @title,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_groups
    if request.get? || request.head?
      render :download
      return
    end

    groups
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::Capital::Groups.new(
      @items, @capitals, @children,
      title: @title,
      encoding: @encoding,
      total: true
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_users
    if request.get? || request.head?
      render :download
      return
    end

    users
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::Capital::GroupUsers.new(
      @items, @capitals, @group, @users,
      title: @title,
      encoding: @encoding,
      total: true
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end
end
