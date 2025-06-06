module Workflow::Approver
  extend ActiveSupport::Concern
  extend SS::Translation

  attr_accessor :workflow_reset, :workflow_cancel_request, :workflow_approver_alternate

  WORKFLOW_STATE_PUBLIC = "public".freeze
  WORKFLOW_STATE_CLOSED = "closed".freeze
  WORKFLOW_STATE_REQUEST = "request".freeze
  WORKFLOW_STATE_APPROVE = "approve".freeze
  WORKFLOW_STATE_APPROVE_WITHOUT_APPROVAL = "approve_without_approval".freeze
  WORKFLOW_STATE_PENDING = "pending".freeze
  WORKFLOW_STATE_REMAND = "remand".freeze
  WORKFLOW_STATE_CANCELLED = "cancelled".freeze
  WORKFLOW_STATE_OTHER_APPROVED = "other_approved".freeze
  WORKFLOW_STATE_OTHER_REMANDED = "other_remanded".freeze
  WORKFLOW_STATE_OTHER_PULLED_UP = "other_pulled_up".freeze

  WORKFLOW_STATE_COMPLETES = [
    WORKFLOW_STATE_APPROVE, WORKFLOW_STATE_APPROVE_WITHOUT_APPROVAL, WORKFLOW_STATE_OTHER_APPROVED,
    WORKFLOW_STATE_OTHER_PULLED_UP
  ].freeze

  WORKFLOW_EDITABLE_STATES = [
    WORKFLOW_STATE_REMAND, WORKFLOW_STATE_CANCELLED, WORKFLOW_STATE_CLOSED
  ].freeze

  included do
    cattr_reader(:approver_user_class) { Cms::User }

    belongs_to :workflow_user, class_name: "Cms::User"
    belongs_to :workflow_agent, class_name: "Cms::User"
    field :workflow_state, type: String
    field :workflow_kind, type: String
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
    field :workflow_reminder_sent_at, type: DateTime
    field :requested, type: DateTime

    permit_params :workflow_user_id, :workflow_state, :workflow_kind, :workflow_comment, :workflow_pull_up, :workflow_on_remand
    permit_params workflow_approvers: []
    permit_params workflow_required_counts: []
    permit_params :workflow_reset, :workflow_cancel_request, :workflow_approver_alternate
    permit_params workflow_circulations: []

    before_validation :reset_workflow, if: -> { workflow_reset.present? && workflow_reset }
    validates :approved, datetime: true
    validates :requested, datetime: true
    validate :validate_workflow_approvers_presence, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_approvers_level_consecutiveness, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }
    validate :validate_workflow_required_counts, if: -> { workflow_state == WORKFLOW_STATE_REQUEST }

    before_save :cancel_request, if: -> { workflow_cancel_request }
    before_save :transfer_workflow_approver_file_ownerships

    after_destroy :destroy_workflow_approver_files

    re_define_method(:workflow_user) do |_reload = false|
      if workflow_user_id.present?
        self.class.approver_user_class.where(id: workflow_user_id).first
      else
        nil
      end
    end

    re_define_method(:workflow_agent) do |_reload = false|
      if workflow_agent_id.present?
        self.class.approver_user_class.where(id: workflow_agent_id).first
      else
        nil
      end
    end
  end

  def status
    return state if state == "public" || state == "ready"
    return state if workflow_state == "cancelled"
    return workflow_state if workflow_state.present?
    state
  end

  def workflow_approvers_and_circulations
    @workflow_approvers_and_circulations.present?
    @workflow_approvers_and_circulations ||= workflow_approvers + workflow_circulations
  end

  def workflow_url
    nil
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

  def workflow_init_kind
    return 'replace' if self.try(:branch?)

    if self.respond_to?(:public?)
      if public?
        return 'closed'
      else
        return 'public'
      end
    end

    nil
  end

  def workflow_current_level
    workflow_levels.each do |level|
      return level unless workflow_completed_at?(level)
    end
    nil
  end

  def workflow_kind_options
    %w(public closed replace).map { |v| [I18n.t("workflow.options.kind.#{v}"), v] }
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

  def workflow_approver_alternator?(user)
    if route_my_group_alternate?
      return workflow_approvers[1][:user_id] == user.id rescue false
    end

    level = workflow_current_level
    approvers = workflow_approvers_at(level)
    approvers.any? { |approver| approver[:user_id] == user.id && approver[:alternate_to].present? }
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
    self.requested = Time.zone.now
    true
  end

  # 代理申請/上位ユーザー
  def set_workflow_approver_target
    return if workflow_agent_id.blank? || workflow_agent.blank? || workflow_user.blank?

    superior_users = workflow_user.gws_superior_users(site)
    superior_user = Gws::User.order_users_by_title(superior_users, cur_site: site).first
    return unless superior_user

    copy_approvers = workflow_approvers.to_a
    copy_approvers.each do |approver|
      if approver[:user_type] == 'superior'
        approver[:user_id] = superior_user.id
      end
    end
    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy_approvers)
  end

  # 所属長承認（代理承認者）
  def set_workflow_approver_alternate
    return unless workflow_approver_alternate

    copy = workflow_approvers.to_a
    copy.delete_at(1)

    user_id = workflow_approver_alternate.presence
    if user_id && user = Gws::User.site(site).find(user_id) rescue nil
      workflow_approver = {}
      workflow_approver[:level] = 1
      workflow_approver[:user_type] = 'Gws::User'
      workflow_approver[:user_id] = user.id
      workflow_approver[:state] = WORKFLOW_STATE_REQUEST
      workflow_approver[:comment] = ''
      copy << workflow_approver
    end
    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
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

    created = Time.zone.now

    copy = workflow_approvers.to_a
    approved_approvers = copy.select { |approver| approver[:level] == level && approver[:user_id] == user_id }
    approved_approvers.each do |approver|
      approver[:state] = WORKFLOW_STATE_APPROVE
      approver[:comment] = comment
      approver[:file_ids] = file_ids
      approver[:created] = created

      # select alternate approvers
      if approver[:alternate_to].present?
        _alternate_to_level, _alternate_to_user_type, alternate_to_user_id = approver[:alternate_to].split(",")
        alternate_to_user_id = alternate_to_user_id.to_i
        alternate_approvers = copy.select do |approver|
          approver[:level] == level && approver[:user_id] == alternate_to_user_id
        end
      else
        expected_alternate_to = [ level, approver[:user_type], user_id ].join(",")
        alternate_approvers = copy.select do |approver|
          approver[:level] == level && approver[:alternate_to] == expected_alternate_to
        end
      end
      next if alternate_approvers.blank?

      alternate_approvers.each do |approver|
        # rubocop:disable Style/Next
        if approver[:level] == level && approver[:state] == WORKFLOW_STATE_REQUEST
          approver[:state] = WORKFLOW_STATE_OTHER_APPROVED
          approver[:comment] = ''
          approver[:created] = created
        end
        # rubocop:enable Style/Next
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)

    if workflow_completed_at?(level)
      copy.each do |approver|
        # rubocop:disable Style/Next
        if approver[:level] == level && approver[:state] == WORKFLOW_STATE_REQUEST
          approver[:state] = WORKFLOW_STATE_OTHER_APPROVED
          approver[:comment] = ''
          approver[:created] = created
        end
        # rubocop:enable Style/Next
      end

      self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    end
  end

  def pull_up_workflow_approver_state(user_or_id, comment: nil, file_ids: nil)
    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    level = workflow_approvers.select { |approver| approver[:user_id] == user_id }.map { |approver| approver[:level] }.max
    return if level.nil?

    # rubocop:disable Style/Next
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
        approver[:created] = Time.zone.now
      end
    end
    # rubocop:enable Style/Next

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
  end

  def remand_workflow_approver_state(user_or_id, comment: nil, file_ids: nil)
    level = workflow_current_level
    return if level.nil?

    user_id = user_or_id.id if user_or_id.respond_to?(:id)
    user_id ||= user_or_id.to_i

    removed_file_ids = []
    copy = workflow_approvers.to_a
    copy.each do |approver|
      if approver[:level] == level
        if approver[:user_id] == user_id
          approver[:state] = WORKFLOW_STATE_REMAND
          approver[:comment] = comment
          approver[:created] = Time.zone.now
          if file_ids
            approver[:file_ids] = file_ids
          else
            approver.delete(:file_ids).try { |file_ids| removed_file_ids += file_ids }
          end
        elsif approver[:state] == WORKFLOW_STATE_REQUEST
          approver[:state] = WORKFLOW_STATE_OTHER_REMANDED
          approver[:comment] = ''
          # approver.delete(:file_ids).try { |file_ids| removed_file_ids += file_ids }
        end
      end
    end

    self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)

    if workflow_back_to_init? || level <= 1
      self.workflow_state = WORKFLOW_STATE_REMAND
    else
      # rubocop:disable Style/Next
      copy.each do |approver|
        if approver[:level] == level - 1
          approver[:state] = WORKFLOW_STATE_REQUEST
          approver[:comment] = ''
          approver.delete(:file_ids).try { |file_ids| removed_file_ids += file_ids }
        end
      end
      # rubocop:enable Style/Next
      self.workflow_approvers = Workflow::Extensions::WorkflowApprovers.new(copy)
    end

    removed_file_ids.compact!
    removed_file_ids
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

  def workflow_editable_state?
    workflow_state.blank? || WORKFLOW_EDITABLE_STATES.include?(workflow_state)
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
    user_ids = circulations.filter_map { |h| h[:user_id] }.uniq
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

  # アクセシビリティチェック
  def accessibility_check_target?
    is_a?(Cms::Page) || is_a?(Article::Page)
  end

  def ignore_alert_to_syntax_check?
    @cur_user.cms_role_permit_any?(@cur_site, %w(edit_cms_ignore_syntax_check))
  end

  # 記事ページのみアクセシビリティチェックを行う
  def can_approve_with_accessibility_errors?
    return true unless accessibility_check_target?
    return true unless %w(public replace).include?(workflow_kind)
    return true if ignore_alert_to_syntax_check?
    !accessibility_errors?(@cur_user, @cur_site)
  end

  def build_syntax_check_contents
    contents = []
    if self.respond_to?(:html) && self.html.present?
      contents << { "id" => "html", "content" => self.html, "resolve" => "html", "type" => "scalar" }
    end

    if self.respond_to?(:column_values)
      self.column_values.each_with_index do |column_value, idx|
        value =
          if column_value.respond_to?(:in_wrap) && column_value.in_wrap.present?
            column_value.in_wrap
          elsif column_value.respond_to?(:value)
            column_value.value
          elsif column_value.respond_to?(:html)
            column_value.html
          elsif column_value.respond_to?(:text)
            column_value.text
          else
            nil
          end
        next if value.blank?
        contents << {
          "id" => "column_#{idx}",
          "content" => value,
          "resolve" => "html",
          "type" => "scalar"
        }
      end
    end
    contents
  end

  def accessibility_errors?(user, site)
    return false unless accessibility_check_target?
    contents = build_syntax_check_contents
    return false if contents.blank?

    result = Cms::SyntaxChecker.check(cur_site: site, cur_user: user, contents: contents)

    accessibility_error = result.errors.any? { |error| error[:msg].present? }
    accessibility_error
  end

  private

  def reset_workflow
    destroy_workflow_approver_files

    self.unset(
      :workflow_user_id, :workflow_agent_id, :workflow_state, :workflow_kind, :workflow_comment, :workflow_pull_up,
      :workflow_on_remand, :workflow_approvers, :workflow_required_counts, :workflow_approver_attachment_uses,
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
        file.owner_item = SS::Model.container_of(self)
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

    def destroy_workflow_files(*workflow_approvers)
      workflow_approvers = Array(workflow_approvers).flatten
      workflow_approvers.compact!
      workflow_approvers.map!(&:with_indifferent_access)
      file_ids = workflow_approvers.map { |workflow_approver| workflow_approver[:file_ids] }.flatten
      return if file_ids.blank?
      file_ids.compact!
      return if file_ids.blank?

      ::SS::File.in(id: file_ids).destroy_all
    end
  end
end
