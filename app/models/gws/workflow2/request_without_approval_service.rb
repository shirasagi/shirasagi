class Gws::Workflow2::RequestWithoutApprovalService
  include ActiveModel::Model

  PERMIT_PARAMS = [
    :workflow_agent_type, :workflow_user_id, :workflow_comment
  ].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :route_id, :route, :item, :ref,
    :workflow_agent_type, :workflow_user_id, :workflow_comment, :stop_sending_notification

  validate :validate_item_form

  define_model_callbacks :approve

  def call
    if invalid?
      SS::Model.copy_errors(self, item)
      return
    end

    if workflow_agent_type.to_s == "agent"
      wk_user = Gws::User.site(cur_site).where(id: workflow_user_id).first
      if wk_user.blank?
        item.errors.add :base, :workflow_user_is_not_selected
        return false
      end
      wk_group = wk_user.gws_main_group(cur_site) rescue nil
      item.update_workflow_user(cur_site, wk_user, wk_group)
      item.update_workflow_agent(cur_site, cur_user, cur_group)
    else
      item.update_workflow_user(cur_site, cur_user, cur_group)
      item.update_workflow_agent(cur_site, nil, nil)
    end
    item.workflow_state = Gws::Workflow2::File::WORKFLOW_STATE_APPROVE_WITHOUT_APPROVAL
    item.workflow_comment = workflow_comment
    item.approved = Time.zone.now
    item.workflow_pull_up = "disabled"
    item.workflow_on_remand = "back_to_init"

    save_workflow_approvers = item.workflow_approvers.dup
    item.workflow_approvers = []
    item.workflow_required_counts = []
    item.workflow_approver_attachment_uses = []

    item.workflow_current_circulation_level = 0
    save_workflow_circulations = item.workflow_circulations.dup
    item.workflow_circulations = []
    item.workflow_circulation_attachment_uses = []

    result = item.save
    return result unless result

    run_callbacks :approve do
      send_destination
    end

    item.class.destroy_workflow_files(save_workflow_approvers, save_workflow_circulations)

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

  def send_destination
    return if stop_sending_notification

    to_users = item.workflow_destination_users
    return if to_users.blank?

    notify_users = to_users.site(cur_site).active.to_a.uniq
    return if notify_users.blank?

    Gws::Memo::Notifier.deliver_workflow_destination!(
      cur_site: cur_site, cur_group: cur_group, cur_user: item.workflow_user,
      to_users: notify_users, item: item, url: ref
    )
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
    false
  end
end
