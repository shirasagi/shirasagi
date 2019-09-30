class Gws::Affair::Overtime::Apis::FilesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Affair::OvertimeFile

  def week_in
    @start_at = Time.zone.parse(params[:year_month_day])
    @user = Gws::User.active.find_by(id: params[:uid])

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_in_compensatory_file_id).compact

    # 日曜始まり 土曜終わり
    @start_of_week = @start_at.to_date.advance(days: (-1 * @start_at.wday))
    @end_of_week = @start_of_week.advance(days: 6)

    @items = @model.site(@cur_site).
      where(
        target_user_id: @user.id,
        workflow_state: "approve",
        week_in_compensatory_minute: { "$gt" => 0 },
        id: { "$nin" => file_ids },
        :start_at.gte => @start_of_week,
        :start_at.lt => @end_of_week.advance(days: 1)
      ).page(params[:page]).per(50)
  end

  def week_out
    @start_at = Time.zone.parse(params[:year_month_day])
    @user = Gws::User.active.find_by(id: params[:uid])

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(workflow_state: "approve").
      pluck(:week_out_compensatory_file_id).compact

    @items = @model.site(@cur_site).where(
      target_user_id: @user.id,
      workflow_state: "approve",
      week_out_compensatory_minute: { "$gt" => 0 },
      id: { "$nin" => file_ids }
    ).to_a
    @items = @items.select { |item| item.in_week_out_compensatory_expiration?(@start_at.to_date) }
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)

    @left_compensatory_minute = (@items.map(&:week_out_compensatory_minute).sum / 60.0)
  end

  def holiday
    @start_at = Time.zone.parse(params[:year_month_day])
    @user = Gws::User.active.find_by(id: params[:uid])

    file_ids = Gws::Affair::LeaveFile.site(@cur_site).where(
      target_user_id: @user.id,
      workflow_state: "approve"
    ).pluck(:holiday_compensatory_file_id).compact

    @items = @model.site(@cur_site).where(
      target_user_id: @user.id,
      workflow_state: "approve",
      holiday_compensatory_minute: { "$gt" => 0 },
      id: { "$nin" => file_ids }
    ).to_a
    @items = @items.select { |item| item.in_week_out_compensatory_expiration?(@start_at.to_date) }
    @items = Kaminari.paginate_array(@items).page(params[:page]).per(50)
  end
end
