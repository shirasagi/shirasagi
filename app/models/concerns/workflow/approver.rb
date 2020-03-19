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
  WORKFLOW_STATE_OTHER_APPROVED = "other_approved".freeze
  WORKFLOW_STATE_OTHER_REMANDED = "other_remanded".freeze
  WORKFLOW_STATE_OTHER_PULLED_UP = "other_pulled_up".freeze

  WORKFLOW_STATE_COMPLETES = [ WORKFLOW_STATE_APPROVE, WORKFLOW_STATE_OTHER_APPROVED, WORKFLOW_STATE_OTHER_PULLED_UP ].freeze

  included do
    cattr_reader(:approver_user_class) { Cms::User }

    field :workflow_user_id, type: Integer
    field :workflow_agent_id, type: Integer
    field :workflow_state, type: String
    field :workflow_comment, type: String
    field :workflow_pull_up, type: String
    field :workflow_on_remand, type: String
    field :workflow_approvers, type: Workflow::Extensions::WorkflowApprovers
    field :workflow_required_counts, type: Workflow::Extensions::Route::RequiredCounts
    field :workflow_approver_attachment_uses, type: Array
    # 現在の回覧ステップ: 0 はまだ回覧が始まっていないことを意味する。
    field :workflow_current_circulation_level, type: Integer, default: 0
    field :workflow_circulations, type: Workflow::Extensions::WorkflowCirculations
    field :workflow_circulation_attachment_uses, type: Array
    field :approved, type: DateTime

    permit_params :workflow_user_id, :workflow_state, :workflow_comment, :workflow_pull_up, :workflow_on_remand
    permit_params workflow_approvers: []
    permit_params workflow_required_counts: []
    permit_params :workflow_reset, :workflow_cancel_request
    permit_params workflow_circulations: []

    before_validation :reset_workflow, if: -> { workflow_reset }
    validates :approved, datetime: true
    validate :validate_workflow_approvers_presence, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_approvers_level_consecutiveness, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_approvers_role, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_required_counts, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }

    before_save :cancel_request, if: -> { workflow_cancel_request }
    before_save :transfer_workflow_approver_file_ownerships

    after_destroy :destroy_workflow_approver_files
  end

  def status
    return state if state == "public" || state == "ready"
    return state if workflow_state == "cancelled"
    return workflow_state if workflow_state.present?
    state
  end

  def workflow_user
    if workflow_user_id.present?
      self.class.approver_user_class.where(id: workflow_user_id).first
    else
      nil
    end
  end

  def workflow_agent
    if workflow_agent_id.present?
      self.class.approver_user_class.where(id: workflow_agent_id).first
    else
      nil
    end
  end

  def workflow_levels
    workflow_approvers.map { |h| h[:level] }.uniq.compact.sort
  end

  def workflow_current_level
    workflow_levels.each do |level|
      return level unless workflow_completed_at?(level)
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

  def workflow_required_count_at(level)
    self.workflow_required_counts[level - 1] || false
  end

  def workflow_approver_attachment_use_at(level)
    return if workflow_approver_attachment_uses.blank?

    index = level - 1
    return if index < 0 || workflow_approver_attachment_uses.length <= index

    workflow_approver_attachment_uses[index]
  end

  def workflow_approver_attachment_enabled_at?(level)
    workflow_approver_attachment_use_at(level) == "enabled"
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

  def approve_workflow_approver_state(user_or_id, comment: nil, file_ids: nil)
    level = workflow_current_level
    return if level.nil?

    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    copy = workflow_approvers.to_a
    copy.each do |approver|
      if approver[:level] == level && approver[:user_id] == user_id
        approver[:state] = WORKFLOW_STATE_APPROVE
        approver[:comment] = comment
        approver[:file_ids] = file_ids
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)

    if workflow_completed_at?(level)
      copy.each do |approver|
        if approver[:level] == level && approver[:user_id] != user_id && approver[:state] == WORKFLOW_STATE_REQUEST
          approver[:state] = WORKFLOW_STATE_OTHER_APPROVED
          approver[:comment] = ''
        end
      end

      self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    end
  end

  def pull_up_workflow_approver_state(user_or_id, comment: nil, file_ids: nil)
    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    level = workflow_approvers.select { |approver| approver[:user_id] == user_id }.map { |approver| approver[:level] }.max
    return if level.nil?

    copy = workflow_approvers.to_a
    copy.each do |approver|
      if approver[:level] < level
        approver[:state] = WORKFLOW_STATE_OTHER_PULLED_UP
        approver[:comment] = ''
      end

      if approver[:level] == level && approver[:user_id] == user_id
        approver[:state] = WORKFLOW_STATE_APPROVE
        approver[:comment] = comment
        approver[:file_ids] = file_ids
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
  end

  def remand_workflow_approver_state(user_or_id, comment = nil)
    level = workflow_current_level
    return if level.nil?

    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    copy = workflow_approvers.to_a
    copy.each do |approver|
      if approver[:level] == level
        if approver[:user_id] == user_id
          approver[:state] = WORKFLOW_STATE_REMAND
          approver[:comment] = comment
        elsif approver[:state] == WORKFLOW_STATE_REQUEST
          approver[:state] = WORKFLOW_STATE_OTHER_REMANDED
          approver[:comment] = ''
        end
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)

    if workflow_back_to_init?
      self.workflow_state = WORKFLOW_STATE_REMAND
    elsif level <= 1
      self.workflow_state = WORKFLOW_STATE_REMAND
    else
      copy.each do |approver|
        if approver[:level] == level - 1
          approver[:state] = WORKFLOW_STATE_REQUEST
          approver[:comment] = ''
        end
      end
      self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    end
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

  def approve_enabled?(state)
    !approve_disabled?(state)
  end

  def workflow_requested?
    workflow_state == WORKFLOW_STATE_REQUEST
  end

  def find_workflow_request_to(user)
    return if self.workflow_state != "request"

    approvers = self.workflow_pull_up_approvers_at(self.workflow_current_level)
    approvers.find do |approver|
      user.id == approver[:user_id] && self.approve_enabled?(approver[:state])
    end
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

  def workflow_circulation_levels
    workflow_circulations.map { |h| h[:level] }.uniq.compact.sort
  end

  def workflow_circulations_at(level)
    return [] if level == 0

    workflow_circulations.select { |h| h[:level] == level }
  end

  def workflow_circulation_users_at(level)
    circulations = workflow_circulations_at(level)
    user_ids = circulations.map { |h| h[:user_id] }.compact.uniq
    return approver_user_class.none if user_ids.blank?

    approver_user_class.site(@cur_site || self.site).in(id: user_ids)
  end

  def workflow_current_circulation_users
    workflow_circulation_users_at(workflow_current_circulation_level)
  end

  def workflow_circulation_completed_at?(level)
    circulations = workflow_circulations_at(level)
    return false if circulations.blank?

    circulations.all? { |circulation| circulation[:state] == "seen" }
  end

  def workflow_current_circulation_completed?
    workflow_circulation_completed_at?(workflow_current_circulation_level)
  end

  def workflow_circulation_attachment_use_at(level)
    return if workflow_circulation_attachment_uses.blank?

    index = level - 1
    return if index < 0 || workflow_circulation_attachment_uses.length <= index

    workflow_circulation_attachment_uses[index]
  end

  def workflow_circulation_attachment_enabled_at?(level)
    workflow_circulation_attachment_use_at(level) == "enabled"
  end

  def set_workflow_circulation_state_at(level, state: 'unseen', comment: '')
    return false if level == 0

    copy = workflow_circulations.to_a
    targets = copy.select do |workflow_circulation|
      workflow_circulation[:level] == level
    end
    return false if targets.blank?

    targets.each do |workflow_circulation|
      workflow_circulation[:state] = state
      workflow_circulation[:comment] = comment.gsub(/\n|\r\n/, " ") if comment
    end

    # Be careful, partial update is meaningless. We must update entirely.
    self.workflow_circulations = Workflow::Extensions::WorkflowCirculations.new(copy)
    true
  end

  def update_current_workflow_circulation_state(user_or_id, state, comment: nil, file_ids: nil)
    level = workflow_current_circulation_level
    return false if level == 0

    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    copy = workflow_circulations.to_a
    targets = copy.select do |workflow_circulation|
      workflow_circulation[:level] == level && workflow_circulation[:user_id] == user_id
    end
    return false if targets.blank?

    # do loop even though targets length is always 1
    targets.each do |workflow_circulation|
      workflow_circulation[:state] = state
      workflow_circulation[:comment] = comment.gsub(/\n|\r\n/, " ") if comment
      workflow_circulation[:file_ids] = file_ids if file_ids
    end

    # Be careful, partial update is meaningless. We must update entirely.
    self.workflow_circulations = Workflow::Extensions::WorkflowCirculations.new(copy)
    true
  end

  def move_workflow_circulation_next_step
    next_level = workflow_current_circulation_level + 1

    users = workflow_circulation_users_at(next_level).active
    return false if users.blank?

    set_workflow_circulation_state_at(next_level, state: "unseen", comment: "")
    self.workflow_current_circulation_level = next_level
    true
  end

  private

  def reset_workflow
    destroy_workflow_approver_files

    self.unset(
      :workflow_user_id, :workflow_agent_id, :workflow_state, :workflow_comment, :workflow_pull_up, :workflow_on_remand,
      :workflow_approvers, :workflow_required_counts, :workflow_approver_attachment_uses,
      :workflow_current_circulation_level, :workflow_circulations, :workflow_circulation_attachment_uses,
      :approved
    )
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
    return if new_record?
    return if cur_site.nil?
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
      required_count = workflow_required_count_at(level)
      next if required_count == false

      approvers = workflow_approvers_at(level)
      errors.add :base, :required_count_greater_than_approvers, level: level, required_count: required_count \
        if approvers.length < required_count
    end
  end

  def workflow_completed_at?(level)
    required_count = workflow_required_count_at(level)
    approvers = workflow_approvers_at(level)
    required_count = approvers.length if required_count == false
    approved = approvers.count { |approver| WORKFLOW_STATE_COMPLETES.include?(approver[:state]) }
    approved >= required_count
  end

  def validate_user(route, users, *actions)
    actions.each do |action|
      unable_users = users.reject do |_, user|
        allowed?(action, user, site: cur_site, adds_error: false)
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

  def transfer_workflow_approver_file_ownerships(model = 'workflow/approver_file')
    file_ids = workflow_approvers.map { |approver| approver[:file_ids] }.flatten.compact.uniq
    file_ids += workflow_circulations.map { |circulation| circulation[:file_ids] }.flatten.compact.uniq

    not_owned_file_ids = ::SS::File.in(id: file_ids).where(model: "ss/temp_file").pluck(:id)
    not_owned_file_ids.each_slice(20) do |ids|
      ::SS::File.in(id: ids).each do |file|
        file.model = model
        file.save
      end
    end
  end

  def destroy_workflow_approver_files
    self.class.destroy_workflow_files(self.workflow_approvers)
    self.class.destroy_workflow_files(self.workflow_circulations)
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

    def destroy_workflow_files(workflow_approvers)
      file_ids = workflow_approvers.map { |workflow_approver| workflow_approver[:file_ids] }.flatten
      return if file_ids.blank?

      ::SS::File.in(id: file_ids).destroy_all
    end
  end
end
