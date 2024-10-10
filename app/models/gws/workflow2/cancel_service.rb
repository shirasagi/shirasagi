class Gws::Workflow2::CancelService
  include ActiveModel::Model

  PERMIT_PARAMS = [].freeze
  attr_accessor :cur_site, :cur_group, :cur_user, :item, :ref

  def call
    item.approved = nil
    item.workflow_state = Gws::Workflow2::File::WORKFLOW_STATE_CANCELLED
    item.skip_validate_column_values = true
    return false unless item.save

    send_notification
    item.errors.blank?
  end

  private

  def send_notification
    recipients = collect_recipients
    return if recipients.blank?

    recipients -= [ cur_user.id ]
    return if recipients.blank?

    notify_user_ids = recipients.uniq
    return if notify_user_ids.blank?

    Gws::Memo::Notifier.deliver_workflow_cancel!(
      cur_site: cur_site, cur_group: cur_group, cur_user: cur_user,
      to_users: Gws::User.in(id: notify_user_ids).active, item: item, url: ref)
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  # rubocop:disable Rails/Pluck
  def collect_recipients
    recipients = []

    prev_level_approvers = item.workflow_approvers_at(item.workflow_current_level)
    recipients += prev_level_approvers.map { |hash| hash[:user_id] }

    recipients
  end
  # rubocop:enable Rails/Pluck
end
