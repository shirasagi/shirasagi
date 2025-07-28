class Gws::Workflow2::ApprovableValidator < ActiveModel::Validator
  def validate(record)
    if record.item.workflow_state != "request"
      record.errors.add :base, :workflow_application_is_not_requested
      return
    end

    workflow_approver = record.item.find_workflow_request_to(record.cur_user)
    if workflow_approver.blank?
      record.errors.add :base, :you_are_not_approver
      return
    end

    expected_states = %w(request)
    if record.item.workflow_pull_up == "enabled"
      expected_states << 'pending'
    end
    unless expected_states.include?(workflow_approver[:state])
      record.errors.add :base, :you_are_not_approver
    end
  end
end
