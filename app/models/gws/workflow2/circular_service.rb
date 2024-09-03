class Gws::Workflow2::CircularService
  include ActiveModel::Model

  PERMIT_PARAMS = [ :comment, file_ids: [].freeze ].freeze
  attr_accessor :cur_site, :cur_group, :cur_user, :item, :ref, :comment, :file_ids

  def call
    if !item.update_current_workflow_circulation_state(cur_user, "seen", comment: comment, file_ids: file_ids)
      item.errors.add :base, :unable_to_update_cirulaton_state
      return false
    end

    send_comment
    send_circulation

    item.save
  end

  private

  def send_comment
    to_users = [ item.workflow_user, item.workflow_agent ].compact - [ cur_user ]
    to_users.select! { |user| user.active? }
    return if to_users.blank?

    if (comment.present? || file_ids.present?) && to_users.present?
      Gws::Memo::Notifier.deliver_workflow_comment!(
        cur_site: cur_site, cur_group: cur_group, cur_user: cur_user,
        to_users: to_users, item: item, url: ref
      )
    end
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end

  def send_circulation
    if item.workflow_current_circulation_completed? && item.move_workflow_circulation_next_step
      current_circulation_users = item.workflow_current_circulation_users.nin(id: cur_user.id).active
      if current_circulation_users.present?
        Gws::Memo::Notifier.deliver_workflow_circulations!(
          cur_site: cur_site, cur_group: cur_group, cur_user: item.workflow_user,
          to_users: current_circulation_users, item: item, url: ref
        )
      end
    end
  rescue => e
    Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
  end
end
