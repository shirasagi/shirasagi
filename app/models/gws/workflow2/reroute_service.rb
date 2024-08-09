class Gws::Workflow2::RerouteService
  include ActiveModel::Model
  include ActiveModel::Attributes

  PERMIT_PARAMS = %i[level approver_id new_approver_id].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :item, :ref

  attribute :level, :integer
  attribute :approver_id, :integer
  attribute :new_approver_id, :integer

  def call
    workflow_approvers = item.workflow_approvers.to_a.dup
    workflow_approver = workflow_approvers.find do |workflow_approver|
      workflow_approver[:level] == level && workflow_approver[:user_id] == approver_id
    end

    if !workflow_approver
      item.errors.add :base, I18n.t('errors.messages.no_approvers')
      return false
    end

    workflow_approver[:user_id] = new_approver_id
    if workflow_approver[:state] != 'request' && workflow_approver[:state] != 'pending'
      workflow_approver[:state] = 'request'
    end
    workflow_approver[:comment] = ''

    item.workflow_approvers = workflow_approvers
    return false unless item.save

    request_approval if workflow_approver[:state] == 'request'
    item.errors.blank?
  end

  private

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
end
