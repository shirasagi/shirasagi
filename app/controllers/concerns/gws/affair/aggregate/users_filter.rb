module Gws::Affair::Aggregate::UsersFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_cur_month
  end

  private

  def set_cur_month
    if params[:year] && params[:month]
      @cur_month = Time.zone.parse("#{params[:year]}/#{params[:month]}/1")
    else
      @cur_month = Time.zone.today.change(day: 1)
    end
  end

  def set_use_items
    @main_group = @cur_user.gws_main_group(@cur_site)
    @groups = Gws::Group.active.in(id: @main_group.id).to_a
    @group ||= @main_group

    @users = Gws::User.active.in(group_ids: @group.id).in(id: @cur_user.id).order_by_title(@cur_site)
    @descendants = @users
  end

  def set_manage_items
    @main_group = @cur_user.gws_main_group(@cur_site)
    @managed_groups = Gws::Group.active.in(superior_user_ids: @cur_user.id).to_a

    @groups = Gws::Group.active.in_group(@main_group).to_a
    @groups += @managed_groups
    @groups = @groups.uniq(&:id)

    @group = @groups.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @main_group

    @users = Gws::User.active.in(group_ids: @group.id).order_by_title(@cur_site)

    group_ids = Gws::Group.active.in_group(@group).pluck(:id)
    @descendants = Gws::User.active.in(group_ids: group_ids).order_by_title(@cur_site)
  end

  def set_all_items
    @main_group = @cur_user.gws_main_group(@cur_site)
    @groups = Gws::Group.active.in_group(@cur_site).to_a

    @group = @groups.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @main_group

    @users = Gws::User.active.in(group_ids: @group.id).order_by_title(@cur_site)

    group_ids = Gws::Group.active.in_group(@group).pluck(:id)
    @descendants = Gws::User.active.in(group_ids: group_ids).order_by_title(@cur_site)
  end

  def set_items
    if @model.allowed_aggregate?(:all, @cur_user, @cur_site)
      set_all_items
    elsif @model.allowed_aggregate?(:manage, @cur_user, @cur_site)
      set_manage_items
    elsif @model.allowed_aggregate?(:use, @cur_user, @cur_site)
      set_use_items
    else
      raise "403"
    end

    # only not flextime users
    @users = @users.select do |user|
      duty_calendar = user.effective_duty_calendar(@cur_site)
      !duty_calendar.flextime?
    end
  end
end
