module Gws::Affair::OvertimeFile::CreateCompensatory
  extend ActiveSupport::Concern

  def create_week_in_compensatory
    leave_file = week_in_leave_file
    if week_in_start_at.present? && week_in_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = user
      leave_file.cur_site = site
      leave_file.target_user = target_user
      leave_file.target_group = target_group
      leave_file.leave_type = "week_in_compensatory_leave"

      leave_file.week_in_compensatory_file = self
      leave_file.week_out_compensatory_file = nil
      leave_file.holiday_compensatory_file = nil

      leave_file.start_at = week_in_start_at
      leave_file.start_at_date = week_in_start_at_date
      leave_file.start_at_hour = week_in_start_at_hour
      leave_file.start_at_minute = week_in_start_at_minute

      leave_file.end_at = week_in_end_at
      leave_file.end_at_date = week_in_end_at_date
      leave_file.end_at_hour = week_in_end_at_hour
      leave_file.end_at_minute = week_in_end_at_minute

      leave_file.permission_level = permission_level
      leave_file.group_ids = group_ids
      leave_file.user_ids = user_ids
      leave_file.state = state
      leave_file.workflow_user_id = workflow_user_id
      leave_file.workflow_state = workflow_state
      leave_file.workflow_approvers = workflow_approvers
      leave_file.workflow_required_counts = workflow_required_counts
      leave_file.workflow_circulations = workflow_circulations
      leave_file.workflow_current_circulation_level = workflow_current_circulation_level
      leave_file.approved = approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end

  def create_week_out_compensatory
    leave_file = week_out_leave_file
    if week_out_start_at.present? && week_out_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = user
      leave_file.cur_site = site
      leave_file.target_user = target_user
      leave_file.target_group = target_group
      leave_file.leave_type = "week_out_compensatory_leave"

      leave_file.week_in_compensatory_file = nil
      leave_file.week_out_compensatory_file = self
      leave_file.holiday_compensatory_file = nil

      leave_file.start_at = week_out_start_at
      leave_file.start_at_date = week_out_start_at_date
      leave_file.start_at_hour = week_out_start_at_hour
      leave_file.start_at_minute = week_out_start_at_minute

      leave_file.end_at = week_out_end_at
      leave_file.end_at_date = week_out_end_at_date
      leave_file.end_at_hour = week_out_end_at_hour
      leave_file.end_at_minute = week_out_end_at_minute

      leave_file.permission_level = permission_level
      leave_file.group_ids = group_ids
      leave_file.user_ids = user_ids
      leave_file.state = state
      leave_file.workflow_user_id = workflow_user_id
      leave_file.workflow_state = workflow_state
      leave_file.workflow_approvers = workflow_approvers
      leave_file.workflow_required_counts = workflow_required_counts
      leave_file.workflow_circulations = workflow_circulations
      leave_file.workflow_current_circulation_level = workflow_current_circulation_level
      leave_file.approved = approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end

  def create_holiday_compensatory
    leave_file = holiday_compensatory_leave_file
    if holiday_compensatory_start_at.present? && holiday_compensatory_minute.to_i > 0
      leave_file ||= Gws::Affair::LeaveFile.new

      leave_file.cur_user = user
      leave_file.cur_site = site
      leave_file.target_user = target_user
      leave_file.target_group = target_group
      leave_file.leave_type = "holiday_compensatory_leave"

      leave_file.week_in_compensatory_file = nil
      leave_file.week_out_compensatory_file = nil
      leave_file.holiday_compensatory_file = self

      leave_file.start_at = holiday_compensatory_start_at
      leave_file.start_at_date = holiday_compensatory_start_at_date
      leave_file.start_at_hour = holiday_compensatory_start_at_hour
      leave_file.start_at_minute = holiday_compensatory_start_at_minute

      leave_file.end_at = holiday_compensatory_end_at
      leave_file.end_at_date = holiday_compensatory_end_at_date
      leave_file.end_at_hour = holiday_compensatory_end_at_hour
      leave_file.end_at_minute = holiday_compensatory_end_at_minute

      leave_file.permission_level = permission_level
      leave_file.group_ids = group_ids
      leave_file.user_ids = user_ids
      leave_file.state = state
      leave_file.workflow_user_id = workflow_user_id
      leave_file.workflow_state = workflow_state
      leave_file.workflow_approvers = workflow_approvers
      leave_file.workflow_required_counts = workflow_required_counts
      leave_file.workflow_circulations = workflow_circulations
      leave_file.workflow_current_circulation_level = workflow_current_circulation_level
      leave_file.approved = approved

      leave_file.save
    elsif leave_file
      leave_file.destroy
    end
  end
end
