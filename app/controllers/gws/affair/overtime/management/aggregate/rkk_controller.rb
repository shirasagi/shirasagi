class Gws::Affair::Overtime::Management::Aggregate::RkkController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Affair::Overtime::AggregateFilter

  model Gws::Affair::OvertimeDayResult

  navi_view "gws/affair/main/navi"
  menu_view nil

  before_action :set_query

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate"), gws_affair_overtime_management_aggregate_rkk_main_path]
    @crumbs << [t("modules.gws/affair/overtime_file/management/aggregate/rkk"), gws_affair_overtime_management_aggregate_rkk_main_path]
  end

  def set_query
    @staff_type = params.dig(:s, :staff_type).presence || "regular"
    @encoding = params.dig(:s, :encoding).presence

    @s = OpenStruct.new
    @s[:staff_type] = @staff_type
    @s[:encoding] = @encoding
  end

  public

  def index
    redirect_to({ action: :download, fiscal_year: @cur_fiscal_year, month: @cur_month })
  end

  def download
    return if request.get? || request.head?

    @groups = Gws::Group.in_group(@cur_site).active.to_a
    @users = Gws::User.active.in(group_ids: @groups.map(&:id))

    if @staff_type == "regular"
      @users = @users.where(staff_category: "正規職員").order_by_title(@cur_site)
    else
      @users = @users.where(staff_category: "会計年度任用職員").order_by_title(@cur_site)
    end
    cond = [
      { "date_year" => @year },
      { "date_month" => @month },
      { "target_user_id" => { "$in" => @users.pluck(:id) } }
    ]
    @items, _ = @model.site(@cur_site).and(cond).rkk_aggregate
    enum_csv = Gws::Affair::Enumerator::Rkk::RegularUsers.new(@items, @users, @s)

    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "aggregate_rkk_#{Time.zone.now.to_i}.csv"
    )
  end
end
