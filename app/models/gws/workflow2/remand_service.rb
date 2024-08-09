class Gws::Workflow2::RemandService
  include ActiveModel::Model

  PERMIT_PARAMS = [ :comment, file_ids: [].freeze ].freeze
  attr_accessor :cur_site, :cur_group, :cur_user, :type, :item, :ref, :comment, :file_ids

  def call
    removed_file_ids = item.remand_workflow_approver_state(cur_user, comment: comment, file_ids: file_ids)
    return false unless item.save

    SS::File.in(id: removed_file_ids).destroy_all if removed_file_ids.present?

    send_notification
    item.errors.blank?
  end

  private

  def send_notification
    recipients = collect_recipients
    return if recipients.blank?

    recipients -= [cur_user.id]
    return if recipients.blank?

    Gws::Memo::Notifier.deliver_workflow_remand!(
      cur_site: cur_site, cur_group: cur_group, cur_user: cur_user,
      to_users: Gws::User.in(id: recipients).active, item: item, url: ref)
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  # rubocop:disable Rails/Pluck
  def collect_recipients
    recipients = []

    if item.workflow_state == Gws::Workflow2::File::WORKFLOW_STATE_REMAND
      recipients << item.workflow_user_id
      recipients << item.workflow_agent_id if item.workflow_agent_id.present?
    else
      prev_level_approvers = item.workflow_approvers_at(item.workflow_current_level)
      recipients += prev_level_approvers.map { |hash| hash[:user_id] }
    end

    recipients
  end
  # rubocop:enable Rails/Pluck
end
