module Workflow::MemberApprover
  extend ActiveSupport::Concern

  included do
    field :workflow_member_id, type: Integer
  end

  def status_options
    [ Workflow::Approver::WORKFLOW_STATE_PUBLIC, Workflow::Approver::WORKFLOW_STATE_CLOSED,
      Workflow::Approver::WORKFLOW_STATE_REQUEST, Workflow::Approver::WORKFLOW_STATE_APPROVE,
      Workflow::Approver::WORKFLOW_STATE_PENDING, Workflow::Approver::WORKFLOW_STATE_REMAND ].map do |v|
      [ I18n.t("views.options.state.#{v}"), v ]
    end
  end

  def posted_by_options
    %w(admin member).map do |v|
      [ I18n.t("views.options.posted_by.#{v}"), v ]
    end
  end

  def workflow_member
    if workflow_member_id.present?
      Cms::Member.where(id: workflow_member_id).first
    else
      nil
    end
  end

  def apply_status(status, opts = {})
    member = opts[:member]
    route  = opts[:route]
    self.workflow_member_id = member.id if member

    if status == "request"
      self.state = "closed"
      self.workflow_state = "request"
      return false unless route
      return false unless apply_workflow?(route)

      self.workflow_approvers = route.approvers.map do |item|
        item.merge(state: (item[:level] == 1) ? "request" : "pending")
      end
      self.workflow_required_counts = route.required_counts
      return true
    elsif status == "public"
      self.state = "public"
    else
      self.state = "closed"
    end

    if opts[:workflow_reset]
      self.workflow_user_id   = nil
      self.workflow_state     = nil
      self.workflow_comment   = nil
      self.workflow_approvers = nil
    end
    true
  end
end
