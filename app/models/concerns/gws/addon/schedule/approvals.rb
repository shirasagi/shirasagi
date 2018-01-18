module Gws::Addon::Schedule::Approvals
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :approval_check_state, type: String
    embeds_many :approvals, class_name: 'Gws::Schedule::Approval', cascade_callbacks: :true
    validates :approval_check_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
    permit_params :approval_check_state

    scope :no_deny, ->(user){ self.not(approvals: { '$elemMatch' => { user_id: user.id, approval_state: 'deny' }}) }
  end

  def approval_check_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def approval_check_enabled?
    approval_check_state == 'enabled'
  end

  def contains_unknown_approval?
    ids = sorted_overall_members.map(&:id)
    return true if approvals.in(user_id: ids).count != ids.length

    approvals.in(user_id: ids).where(approval_state: 'unknown').present?
  end

  # TODO:
  def approver_ids
    member_ids
  end

  def approval_state
    return 'request' if approvals.size < approver_ids.size
    state = 'approve'
    approvals.each do |item|
      return 'deny' if item.approval_state == 'deny'
      state = 'request' if item.approval_state != 'approve'
    end
    state
  end
end
