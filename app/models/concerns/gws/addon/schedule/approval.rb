module Gws::Addon::Schedule::Approval
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :approval_state, type: String

    embeds_ids :approval_members, class_name: "Gws::User"
    embeds_many :approvals, class_name: 'Gws::Schedule::Approval', cascade_callbacks: true

    permit_params :approval_state
    permit_params approval_member_ids: []

    #validates :approval_check_state, inclusion: { in: %w(disabled enabled), allow_blank: true }
    validate :valdiate_approval_state
  end

  private

  def valdiate_approval_state
    self.approval_state ||= 'request'
    return unless @reset_approvals

    if cur_user && approval_member?(cur_user)
      #
    elsif approved_and_locked?
      errors.add :base, :edit_approved
    else
      self.approval_state = approval_present? ? 'request' : nil
      self.approvals = []
    end
  end

  public

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
  end

  def approval_facilities
    facilities.where(approval_check_state: 'enabled')
  end

  def facility_approver_ids
    approval_facilities.map(&:user_ids).flatten.uniq
  end

  def all_approvers
    ids = approval_member_ids + facility_approver_ids
    Gws::User.in(id: ids.uniq)
  end

  def approval_member?(user)
    approval_member_ids.include?(user.id) || facility_approver_ids.include?(user.id)
  end

  def approval_member(user)
    cond = { user_id: user.id, facility_id: nil }
    approvals.where(cond).order_by(created: 1).first || approvals.new(cond)
  end

  def approval_facility_member(facility)
    cond = { facility_id: facility.id }
    approvals.where(cond).order_by(updated: -1).first || approvals.new(cond)
  end

  def update_approval_state(user)
    self.cur_site = site
    self.cur_user = user
    self.approval_state = current_approval_state
    #self.user_ids += [user.id] if approval_state == "deny"
    update
  end

  def current_approval_state
    if approval_facilities.blank?
      # 通常のスケジュール承認：全てのユーザーの承認状態
      items = approvals
    else
      # 設備予約の承認：設備毎にて一番新しい承認状態
      items = {}
      approvals.order_by(updated: -1).each do |item|
        items[item.facility_id] ||= item
      end
      items = items.values
    end

    status = 'approve'
    items.each do |item|
      return 'deny' if item.approval_state == 'deny'
      status = 'request' if item.approval_state != 'approve'
    end
    return 'request' if approvals.size < approval_member_ids.size + approval_facilities.size
    status
  end

  def approved_and_locked?
    return false if approval_state != "approve"
    approval_facilities.where(update_approved_state: "enabled").present?
  end

  module ClassMethods
    #def exclude_denied_plans(user)
    #  criteria = self.criteria
    #  return criteria.ne(approval_state: "deny") if user.nil?
    #
    #  cond = []
    #  cond << { approval_state: { "$ne" => "deny" }  }
    #  cond << { "$and" => [
    #    { approval_state: "deny" },
    #    { user_ids: { "$in" => [user.id] } }
    #  ]}
    #  criteria.where("$or" => cond)
    #end
  end
end
