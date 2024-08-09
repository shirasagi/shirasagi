class Gws::Workflow2::ApproveService
  include ActiveModel::Model

  PERMIT_PARAMS = [ :comment, file_ids: [].freeze ].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :type, :item, :ref, :comment, :file_ids

  def initialize(*args)
    super
    self.type = :approve
  end

  def call
    save_level = item.workflow_current_level
    if type == :pull_up
      item.pull_up_workflow_approver_state(cur_user, comment: comment, file_ids: file_ids)
    else
      item.approve_workflow_approver_state(cur_user, comment: comment, file_ids: file_ids)
    end

    if item.finish_workflow?
      item.approved = Time.zone.now
      item.workflow_state = Gws::Workflow2::File::WORKFLOW_STATE_APPROVE
    end

    return false unless item.save

    current_level = item.workflow_current_level
    if !item.finish_workflow? && save_level != current_level
      # escalate workflow
      send_request
    end

    workflow_state = item.workflow_state
    if workflow_state == Gws::Workflow2::File::WORKFLOW_STATE_APPROVE
      # finished workflow
      send_approve
      send_destination
      send_circulation
    end

    item.errors.blank?
  end

  # rubocop:disable Rails/Pluck
  def send_request
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

  def send_approve
    to_user_ids = [ item.workflow_user_id, item.workflow_agent_id ].compact - [ cur_user.id ]
    return if to_user_ids.blank?

    notify_user_ids = to_user_ids.uniq
    return if notify_user_ids.blank?

    Gws::Memo::Notifier.deliver_workflow_approve!(
      cur_site: cur_site, cur_group: cur_group, cur_user: cur_user,
      to_users: Gws::User.in(id: notify_user_ids).active, item: item, url: ref
    )
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  def send_destination
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
  end

  def send_circulation
    return unless item.move_workflow_circulation_next_step

    current_circulation_users = item.workflow_current_circulation_users.nin(id: cur_user.id).active
    if current_circulation_users.present?
      Gws::Memo::Notifier.deliver_workflow_circulations!(
        cur_site: cur_site, cur_group: cur_group, cur_user: item.workflow_user,
        to_users: current_circulation_users, item: item, url: ref
      )
    end

    item.save
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
end
