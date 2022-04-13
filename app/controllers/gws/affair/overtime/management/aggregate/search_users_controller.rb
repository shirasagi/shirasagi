class Gws::Affair::Overtime::Management::Aggregate::SearchUsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  helper Gws::Affair::TimeHelper

  navi_view "gws/affair/main/navi"

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_search_users_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/search_users"), gws_affair_overtime_management_aggregate_search_users_main_path]
  end

  def set_query
    @user_ids = params.dig(:s, :user_ids).to_a.select(&:present?).map(&:to_i)

    @s = OpenStruct.new
    @s[:user_ids] = @user_ids
  end

  def set_items
    @users = Gws::User.in(id: @user_ids).to_a
    @title = I18n.t("gws/affair.labels.overtime.search.title", year: @fiscal_year, month: @month)
    @items, _ = @model.site(@cur_site).where(date_fiscal_year: @fiscal_year, date_month: @month).capital_aggregate_by_users
  end

  public

  def index
    redirect_to({ action: :search, fiscal_year: @cur_fiscal_year, month: @cur_month })
  end

  def search
    @users = Gws::User.in(id: @user_ids).to_a
  end

  def results
    set_capitals
    set_items
    @download_url = url_for({ action: :download, s: @s.to_h }) if @users.present?
  end

  def download
    return if request.get? || request.head?

    results
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::Capital::Users.new(
      @items, @capitals, @users,
      title: @title,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_capitals_#{Time.zone.now.to_i}.csv"
    )
  end
end
