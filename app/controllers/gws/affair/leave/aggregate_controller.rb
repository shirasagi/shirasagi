class Gws::Affair::Leave::AggregateController < ApplicationController
  include Gws::BaseFilter
  include Gws::Affair::Aggregate::UsersFilter

  model Gws::Affair::LeaveFile

  navi_view "gws/affair/main/navi"

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t('modules.gws/affair/leave_file/aggregate'), gws_affair_leave_aggregate_path]
  end

  public

  def index
    set_items
  end

  def show
    set_items
    @user = @users.select { |user| user.id == params[:uid].to_i }.first
    raise "403" if @user.nil?

    @item = Gws::Affair::LeaveSetting.and_date(@cur_site, @user, @cur_month).first
  end

  def download
    raise "403" if !@model.allowed_aggregate?(:manage, @cur_user, @cur_site)

    set_items
    return if request.get? || request.head?

    start_at = @cur_month.change(day: 1)
    end_at = @cur_month.end_of_month

    @target_users = params.dig(:s, :target_users)
    user_ids = (@target_users == "descendants") ? @descendants.pluck(:id) : @users.pluck(:id)

    @encoding = params.dig(:s, :encoding)
    @items = @model.site(@cur_site).and([
      { "target_user_id" => { "$in" => user_ids } },
      { "leave_type" => { "$in" => ["annual_leave", "paidleave"] } },
      { "state" => "approve" },
      { "end_at" => { "$gte" => start_at } },
      { "start_at" => { "$lt" => end_at } }
    ]).reorder(start_at: 1).to_a

    @items.each do |file|
      file.leave_dates_in_query = file.leave_dates.select { |leave_date| leave_date.date >= start_at && leave_date.date <= end_at }
      file.leave_minutes_in_query = file.leave_dates.map(&:minute).sum
    end

    enum_csv = Gws::Affair::Enumerator::LeaveFile.new(@items)
    send_enum(enum_csv,
      type: "text/csv; charset=#{@encoding}",
      filename: "leave_files_#{Time.zone.now.to_i}.csv"
    )
  end
end
