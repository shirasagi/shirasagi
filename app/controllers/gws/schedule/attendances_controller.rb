class Gws::Schedule::AttendancesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Memo::NotificationFilter

  model Gws::Schedule::Attendance

  navi_view "gws/schedule/main/navi"

  private

  def set_cur_schedule
    @cur_schedule ||= Gws::Schedule::Plan.find(params[:plan_id])
  end

  def set_target_user
    set_cur_schedule

    @target_user = @cur_schedule.members.where(id: params[:user_id]).first
    @target_user ||= begin
      member_ids = @cur_schedule.member_custom_groups.pluck(:member_ids).flatten
      Gws::User.in(id: member_ids).where(id: params[:user_id]).first
    end

    raise '404' unless @target_user

    @target_user.cur_site = @cur_site
  end

  def fix_params
    set_cur_schedule
    set_target_user

    ret = { cur_user: @target_user }
    ret[:attendance_state] = params.dig(:item, :attendance_state) if params[:item].present?
    ret
  end

  def set_item
    set_cur_schedule
    set_target_user

    @item = @cur_schedule.attendances.where(user_id: @target_user.id).first_or_create
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def post_comment
    return if params[:comment].blank?

    safe_params = params.require(:comment).permit(Gws::Schedule::Comment.permitted_fields)
    return if safe_params[:text].blank?

    safe_params.reverse_merge!(
      cur_site: @cur_site, cur_user: @target_user, cur_schedule: @cur_schedule, text_type: 'plain'
    )
    Gws::Schedule::Comment.create(safe_params)
  end

  public

  def edit
    raise "403" unless @cur_schedule.member?(@cur_user) || @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site)
    @item.valid?
    render(layout: 'ss/ajax')
  end

  def update
    raise "403" unless @cur_schedule.member?(@cur_user) || @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)

    render_opts = {
      location: CGI.unescapeHTML(params[:redirect_to])
    }

    result = @item.save
    if result
      post_comment
    end
    render_update result, render_opts
  end
end
