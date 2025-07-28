class Gws::Affair::Overtime::Aggregate::UsersController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::PermissionFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  helper Gws::Affair::TimeHelper

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_cur_fiscal_year
  before_action :set_cur_month
  before_action :set_fiscal_year
  before_action :set_month
  before_action :set_query, except: :index

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime/aggregate"), gws_affair_overtime_aggregate_main_path]
    @crumbs << [t("modules.gws/affair/overtime/aggregate/user"), gws_affair_overtime_aggregate_users_main_path]
  end

  def set_query
    @group_id = params.dig(:s, :group_id).presence || @cur_user.gws_main_group(@cur_site).id
    @group_id = @group_id.to_i
    @basic_code = params.dig(:s, :basic_code).presence

    @s = OpenStruct.new
    @s[:group_id] = @group_id
    @s[:basic_code] = @basic_code
  end

  def set_items
    @group = @result_groups.find_group(@group_id) || @result_groups.first
    @users = @group ? @group.users : []
    @items, = @model.site(@cur_site).and([
      { "date_fiscal_year" => @fiscal_year },
      { "date_month" => @month },
      { "target_user_id" => { "$in" => @users.map(&:id) } }
    ]).user_aggregate
  end

  public

  def index
    redirect_to({ action: :total, fiscal_year: @cur_fiscal_year, month: @cur_month })
  end

  def total
    set_capitals
    set_result_groups
    set_items
    @download_url = url_for({ action: :download_total, s: @s.to_h })
  end

  def under
    set_capitals
    set_result_groups
    set_items
    @download_url = url_for({ action: :download_under, s: @s.to_h })
  end

  def over
    set_capitals
    set_result_groups
    set_items
    @download_url = url_for({ action: :download_over, s: @s.to_h })
  end

  def download_total
    if request.get? || request.head?
      render :download
      return
    end

    total
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::User::Total.new(
      @items, @users,
      capital_basic_code: @basic_code,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_total_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_under
    if request.get? || request.head?
      render :download
      return
    end

    under
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::User::Under.new(
      @items, @users,
      capital_basic_code: @basic_code,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_under_#{Time.zone.now.to_i}.csv"
    )
  end

  def download_over
    if request.get? || request.head?
      render :download
      return
    end

    over
    @encoding = params.dig(:s, :encoding)

    enum_csv = Gws::Affair::Enumerator::User::Over.new(
      @items, @users,
      capital_basic_code: @basic_code,
      encoding: @encoding
    )
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_over_#{Time.zone.now.to_i}.csv"
    )
  end
end
