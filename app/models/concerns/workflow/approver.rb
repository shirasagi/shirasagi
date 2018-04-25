module Workflow::Approver
  extend ActiveSupport::Concern

  attr_accessor :workflow_reset, :workflow_cancel_request

  WORKFLOW_STATE_PUBLIC = "public".freeze
  WORKFLOW_STATE_CLOSED = "closed".freeze
  WORKFLOW_STATE_REQUEST = "request".freeze
  WORKFLOW_STATE_APPROVE = "approve".freeze
  WORKFLOW_STATE_PENDING = "pending".freeze
  WORKFLOW_STATE_REMAND = "remand".freeze
  WORKFLOW_STATE_CANCELLED = "cancelled".freeze

  included do
    cattr_reader(:approver_user_class) { Cms::User }

    field :workflow_user_id, type: Integer
    field :workflow_state, type: String
    field :workflow_comment, type: String
    field :workflow_pull_up, type: String
    field :workflow_on_remand, type: String
    field :workflow_approvers, type: Workflow::Extensions::WorkflowApprovers
    field :workflow_required_counts, type: Workflow::Extensions::Route::RequiredCounts
    field :approved, type: DateTime

    permit_params :workflow_user_id, :workflow_state, :workflow_comment, :workflow_pull_up, :workflow_on_remand
    permit_params workflow_approvers: []
    permit_params workflow_required_counts: []
    permit_params :workflow_reset, :workflow_cancel_request

    before_validation :reset_workflow, if: -> { workflow_reset }
    validates :approved, datetime: true
    validate :validate_workflow_approvers_presence, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_approvers_level_consecutiveness, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_approvers_role, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_required_counts, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }

    before_save :cancel_request, if: -> { workflow_cancel_request }
  end

  def status
    return state if state == "public" || state == "ready"
    return state if workflow_state == "cancelled"
    return workflow_state if workflow_state.present?
    state
  end

  def workflow_user
    if workflow_user_id.present?
      SS::User.where(id: workflow_user_id).first
    else
      nil
    end
  end

  def workflow_levels
    workflow_approvers.map { |h| h[:level] }.uniq.compact.sort
  end

  def workflow_current_level
    workflow_levels.each do |level|
      return level unless complete?(level)
    end
    nil
  end

  def workflow_approvers_at(level)
    return [] if level.nil?
    self.workflow_approvers.select do |workflow_approver|
      workflow_approver[:level] == level
    end
  end

  def workflow_pull_up_approvers_at(level)
    return [] if level.nil?
    self.workflow_approvers.select do |workflow_approver|
      next workflow_approver[:level] >= level if self.workflow_pull_up == 'enabled'
      next workflow_approver[:level] == level unless self.workflow_pull_up == 'enabled'
      false
    end
  end

  def workflow_required_counts_at(level)
    self.workflow_required_counts[level - 1] || false
  end

  def set_workflow_approver_state_to_request(level = workflow_current_level)
    return false if level.nil?

    copy = workflow_approvers.to_a
    copy.each do |workflow_approver|
      if workflow_approver[:level] == level
        workflow_approver[:state] = WORKFLOW_STATE_REQUEST
        workflow_approver[:comment] = ''
      end
    end

    # Be careful, partial update is meaningless. We must update entirely.
    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    true
  end

  def update_current_workflow_approver_state(user_or_id, state, comment = nil)
    level = workflow_current_level
    return false if level.nil?

    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    copy = workflow_approvers.to_a
    targets = copy.select do |workflow_approver|
      workflow_approver[:level] == level && workflow_approver[:user_id] == user_id
    end
    # do loop even though targets length is always 1
    targets.each do |workflow_approver|
      workflow_approver[:state] = state
      workflow_approver[:comment] = comment.gsub(/\n|\r\n/, " ") if comment.present?
    end

    # Be careful, partial update is meaningless. We must update entirely.
    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    true
  end

  def pull_up_workflow_approver_state(user_or_id, state, comment = nil)
    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    level = workflow_approvers.select { |approver| approver[:user_id] == user_id }.map { |approver| approver[:level] }.max
    return if level.nil?

    copy = workflow_approvers.to_a
    copy.each do |approver|
      if approver[:level] < level
        approver[:state] = WORKFLOW_STATE_APPROVE
      end

      if approver[:level] == level && approver[:user_id] == user_id
        approver[:state] = state
        approver[:comment] = comment
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
  end

  def finish_workflow?
    workflow_current_level.nil?
  end

  def apply_workflow?(route)
    route.validate
    if route.errors.present?
      route.errors.full_messages.each do |m|
        errors.add :base, m
      end
      return false
    end

    users = route.approvers.map do |approver|
      [ approver[:level], self.class.approver_user_class.where(id: approver[:user_id]).first ]
    end
    users = users.select { |_, user| user.present? }

    validate_user(route, users, :read, :approve)
    errors.empty?
  end

  def approve_disabled?(state)
    return false if self.workflow_pull_up == 'enabled' && state == WORKFLOW_STATE_PENDING
    return false if state == WORKFLOW_STATE_REQUEST
    true
  end

  def workflow_requested?
    workflow_state == WORKFLOW_STATE_REQUEST
  end

  def workflow_approver_editable?(user)
    approvers = workflow_approvers.select do |h|
      h[:state] == WORKFLOW_STATE_REQUEST && h[:user_id] == user.id && h[:editable].present?
    end
    max_editable_approvers = approvers.max_by { |h| h[:editable].to_i }
    return if max_editable_approvers.blank?
    max_editable_approvers[:editable].to_i > 0
  end

  def workflow_back_to_previous?
    workflow_on_remand == 'back_to_previous'
  end

  def workflow_back_to_init?
    !workflow_back_to_previous?
  end

  private

  def reset_workflow
    self.unset(:workflow_user_id, :workflow_state, :workflow_comment, :workflow_approvers)
  end

  def cancel_request
    return if state == "public"
    return if workflow_state != "request"
    return if @cur_user.nil? || workflow_user.nil?
    return if @cur_user.id != workflow_user.id

    reset_workflow
    self.set(workflow_state: WORKFLOW_STATE_CANCELLED)
  end

  def validate_workflow_approvers_presence
    errors.add :workflow_approvers, :not_select if workflow_approvers.blank?

    # check whether approver's required field is given.
    workflow_approvers.each do |workflow_approver|
      errors.add :workflow_approvers, :level_blank if workflow_approver[:level].blank?
      errors.add :workflow_approvers, :user_id_blank if workflow_approver[:user_id].blank?
      errors.add :workflow_approvers, :state_blank if workflow_approver[:state].blank?
    end
  end

  def validate_workflow_approvers_level_consecutiveness
    # level must start from 1 and level must be consecutive.
    check = 1
    workflow_levels.each do |level|
      errors.add :base, :approvers_level_missing, level: check unless level == check
      check = level + 1
    end
  end

  def validate_workflow_approvers_role
    return if errors.present?

    # check whether approvers have read permission.
    users = workflow_approvers.map do |approver|
      self.class.approver_user_class.where(id: approver[:user_id]).first
    end
    users = users.select(&:present?)
    users.each do |user|
      errors.add :workflow_approvers, :not_read, name: user.name unless allowed?(:read, user, site: cur_site)
      errors.add :workflow_approvers, :not_approve, name: user.name unless allowed?(:approve, user, site: cur_site)
    end
  end

  def validate_workflow_required_counts
    errors.add :workflow_required_counts, :not_select if workflow_required_counts.blank?

    workflow_levels.each do |level|
      required_count = workflow_required_counts_at(level)
      next if required_count == false

      approvers = workflow_approvers_at(level)
      errors.add :base, :required_count_greater_than_approvers, level: level, required_count: required_count \
        if approvers.length < required_count
    end
  end

  def complete?(level)
    required_counts = workflow_required_counts_at(level)
    approvers = workflow_approvers_at(level)
    required_counts = approvers.length if required_counts == false
    approved = approvers.count { |approver| approver[:state] == WORKFLOW_STATE_APPROVE }
    approved >= required_counts
  end

  def validate_user(route, users, *actions)
    actions.each do |action|
      unable_users = users.reject do |_, user|
        allowed?(action, user, site: cur_site)
      end
      unable_users.each do |level, user|
        errors.add :base, "route_approver_unable_to_#{action}".to_sym, route: route.name, level: level, user: user.name
      end
    end
  end

  def workflow_pull_up_options
    %w(enabled disabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def workflow_on_remand_options
    %w(back_to_init back_to_previous).map { |v| [I18n.t("workflow.options.on_remand.#{v}"), v] }
  end

  module ClassMethods
    def search(params)
      return criteria if params.blank?

      criteria = super
      if params[:status].present?
        status = params[:status]
        if %w(public closed ready).include?(status)
          criteria = criteria.in(state: status)
        else
          criteria = criteria.in(workflow_state: status)
        end
      end
      criteria
    end
  end
end
