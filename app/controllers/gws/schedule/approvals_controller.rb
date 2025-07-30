class Gws::Schedule::ApprovalsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  #include Gws::Memo::NotificationFilter

  model Gws::Schedule::Approval

  navi_view "gws/schedule/main/navi"

  private

  def set_cur_schedule
    @cur_schedule ||= Gws::Schedule::Plan.find(params[:plan_id])
  end

  def set_target_user
    set_cur_schedule

    return if @target_user
    target_user = Gws::User.site(@cur_site).active.where(id: params[:user_id]).first
    raise '404' unless target_user

    visible = false
    visible = true if @cur_schedule.member?(target_user)
    visible = true if !visible && @cur_schedule.readable?(target_user, site: @cur_site)
    visible = true if !visible && @cur_schedule.allowed?(:read, target_user, site: @cur_site)
    raise '404' unless visible

    @target_user = target_user
    @target_user.cur_site = @cur_site
  end

  def fix_params
    set_cur_schedule
    set_target_user

    ret = { cur_user: @target_user }
    ret[:approval_state] = params.dig(:item, :approval_state) if params[:item].present?
    ret
  end

  def set_item
    set_cur_schedule
    set_target_user

    cond = { user_id: @target_user.id, facility_id: get_params[:facility_id].to_s.presence }

    @item = @cur_schedule.approvals.where(cond).first_or_create
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

  def send_approval_approve_mail
    exclusion_user_ids = @cur_schedule.members.reject{ |user| user.use_notice?(@cur_schedule) }.map(&:id)
    exclusion_user_ids << @cur_user.id
    exclusion_user_ids.uniq!

    Gws::Schedule::Notifier::Approval.deliver_approve!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @cur_schedule.members.nin(id: exclusion_user_ids), item: @cur_schedule,
      url: gws_schedule_plan_url(id: @cur_schedule),
      comment: params.dig(:comment, :text)
    ) rescue nil
  end

  def send_approval_deny_mail
    exclusion_user_ids = @cur_schedule.members.reject{ |user| user.use_notice?(@cur_schedule) }.map(&:id)
    exclusion_user_ids << @cur_user.id
    exclusion_user_ids.uniq!

    Gws::Schedule::Notifier::Approval.deliver_remand!(
      cur_site: @cur_site, cur_group: @cur_group, cur_user: @cur_user,
      to_users: @cur_schedule.members.nin(id: exclusion_user_ids), item: @cur_schedule,
      url: gws_schedule_plan_url(id: @cur_schedule),
      comment: params.dig(:comment, :text)
    ) rescue nil
  end

  public

  def edit
    raise "403" unless @cur_schedule.member?(@cur_user) ||
                       @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site) ||
                       @cur_schedule.approval_member?(@cur_user)
    @item.valid?
    render(layout: 'ss/ajax')
  end

  def update
    raise "403" unless @cur_schedule.member?(@cur_user) ||
                       @cur_schedule.allowed_for_managers?(:edit, @cur_user, site: @cur_site) ||
                       @cur_schedule.approval_member?(@cur_user)
    @item.attributes = get_params
    #@item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    @item.updated = Time.zone.now

    render_opts = {
      location: CGI.unescapeHTML(params[:redirect_to])
    }

    result = @item.save
    if result
      post_comment

      @cur_schedule = @cur_schedule.class.find(@cur_schedule.id) # nocache
      @cur_schedule.update_approval_state(@cur_user)
      if @cur_schedule.approval_state == 'approve'
        send_approval_approve_mail
      elsif @cur_schedule.approval_state == 'deny'
        send_approval_deny_mail
      end
    end
    render_update result, render_opts
  end
end
