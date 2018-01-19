module Gws::Addon::Schedule::Approval
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :approval_state, type: String

    embeds_ids :approval_members, class_name: "Gws::User"
    embeds_many :approvals, class_name: 'Gws::Schedule::Approval', cascade_callbacks: :true

    permit_params :approval_state
    permit_params approval_member_ids: []

    #validates :approval_check_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def approval_state_options
    %w(request approve deny).map do |v|
      [ I18n.t("gws/schedule.options.approved_state.#{v}"), v ]
    end
  end

  def approval_present?
    approval_members.present? || approval_facilities.present?
  end

  def reset_approvals
    @reset_approvals = true
    self.approval_state = approval_present? ? 'request' : nil
    self.approvals = []
  end

  def approval_facilities
    facilities.where(approval_check_state: 'enabled')
  end

  def facility_approver_ids
    approval_facilities.map(&:user_ids).flatten.uniq
  end

  def approval_member?(user)
    approval_member_ids.include?(user.id) || facility_approver_ids.include?(user.id)
  end

  def approval_member(user, opts = {})
    if opts[:facility_id].present?
      cond = { facility_id: opts[:facility_id] }
    else
      cond = { user_id: user.id, facility_id: nil }
    end
    approvals.where(cond).order_by(created: 1).first || approvals.new(cond)
  end

  def update_approval_state
    set(approval_state: current_approval_state)
  end

  def current_approval_state
    status = 'approve'
    approvals.each do |item|
      return 'deny' if item.approval_state == 'deny'
      status = 'request' if item.approval_state != 'approve'
    end

    return 'request' if approvals.size < approval_member_ids.size + approval_facilities.size
    status
  end
end
