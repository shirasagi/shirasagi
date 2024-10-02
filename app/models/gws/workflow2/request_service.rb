class Gws::Workflow2::RequestService
  include ActiveModel::Model

  PERMIT_PARAMS = [
    :workflow_agent_type, :workflow_user_id, :workflow_comment, :workflow_approver_alternate
  ].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :route_id, :route, :item, :ref,
    :workflow_agent_type, :workflow_user_id, :workflow_comment, :workflow_approver_alternate

  validate :validate_item_form

  def call
    if invalid?
      SS::Model.copy_errors(self, item)
      return
    end

    item.approved = nil
    if workflow_agent_type.to_s == "agent"
      item.update_workflow_user(cur_site, Gws::User.site(cur_site).where(id: workflow_user_id).first)
      item.update_workflow_agent(cur_site, cur_user)
    else
      item.update_workflow_user(cur_site, cur_user)
      item.update_workflow_agent(cur_site, nil)
    end
    item.workflow_state = Gws::Workflow2::File::WORKFLOW_STATE_REQUEST
    item.workflow_comment = workflow_comment
    save_workflow_approvers_was = item.workflow_approvers_was
    save_workflow_approvers = item.workflow_approvers.dup
    reset_workflow_approvers(item)
    save_workflow_circulations_was = item.workflow_circulations_was
    save_workflow_circulations = item.workflow_circulations.dup
    reset_workflow_circulations(item)

    result = item.valid?
    unless result
      item.workflow_approvers = save_workflow_approvers
      item.workflow_circulations = save_workflow_circulations
      return result
    end

    result = request_approval
    item.class.destroy_workflow_files(save_workflow_approvers_was, save_workflow_circulations_was)

    result
  end

  private

  def validate_item_form
    if item.form_id && item.form.blank?
      errors.add :base, :unable_to_request_due_to_deleted_form
      return
    end

    if item.form.closed?
      errors.add :base, :unable_to_request_due_to_closed_form
    end
  end

  # rubocop:disable Rails/Pluck
  def request_approval
    current_level = item.workflow_current_level

    to_user_ids = item.workflow_approvers_at(current_level).map { |approver| approver[:user_id] }
    to_user_ids.compact!
    to_user_ids.uniq!
    to_user_ids.delete(cur_user.id)
    if to_user_ids.present?
      Gws::Memo::Notifier.deliver_workflow_request!(
        cur_site: cur_site, cur_group: cur_group, cur_user: item.workflow_user,
        to_users: Gws::User.in(id: to_user_ids).active, item: item, url: ref
      )
    end

    item.set_workflow_approver_state_to_request
    item.save
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
  # rubocop:enable Rails/Pluck

  def reset_workflow_approvers(item)
    item.workflow_approver_alternate = workflow_approver_alternate
    item.set_workflow_approver_target
    item.set_workflow_approver_alternate
    item.workflow_approvers = item.workflow_approvers.map do |approver|
      approver = approver.slice(:level, :user_type, :user_id, :state, :editable)
      approver[:state] = "pending" if approver[:user_id].present?
      approver
    end
  end

  def reset_workflow_circulations(item)
    item.workflow_current_circulation_level = 0
    item.workflow_circulations = item.workflow_circulations.map do |circulation|
      circulation = circulation.slice(:level, :user_type, :user_id, :state)
      circulation[:state] = "pending" if circulation[:user_id].present?
      circulation
    end
  end
end
