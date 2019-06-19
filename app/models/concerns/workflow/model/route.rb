module Workflow::Model::Route
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  MAX_APPROVERS = 5
  MAX_CIRCULATIONS = 3

  included do
    store_in collection: "workflow_routes"

    cattr_reader(:approver_user_class) { Cms::User }

    seqid :id
    field :name, type: String
    field :pull_up, type: String
    field :on_remand, type: String
    embeds_ids :groups, class_name: "SS::Group"
    field :approvers, type: Workflow::Extensions::Route::Approvers
    field :required_counts, type: Workflow::Extensions::Route::RequiredCounts
    field :approver_attachment_uses, type: Array
    field :circulations, type: Workflow::Extensions::Route::Circulations
    field :circulation_attachment_uses, type: Array
    permit_params :name, :pull_up, :on_remand, group_ids: []
    permit_params approvers: [ :level, :user_id, :editable ], required_counts: [], approver_attachment_uses: []
    permit_params circulations: [ :level, :user_id ], circulation_attachment_uses: []

    validates :name, presence: true, length: { maximum: 40 }
    validates :pull_up, inclusion: { in: %w(enabled disabled), allow_blank: true }
    validates :on_remand, inclusion: { in: %w(back_to_init back_to_previous), allow_blank: true }
    validate :validate_groups
    validate :validate_approvers_presence
    validate :validate_approvers_consecutiveness
    validate :validate_required_counts
    validate :validate_approver_attachment_uses
    validate :validate_circulation_attachment_uses

    default_scope ->{ order_by name: 1 }
  end

  module ClassMethods
    def route_options(user, options = {})
      ret = []
      if options[:item].present? && options[:item].workflow_approvers.present?
        ret << [ I18n.t("workflow.restart_workflow"), "restart" ]
      end
      ret << [ t("my_group"), "my_group" ] unless SS.config.workflow.disable_my_group
      group_ids = user.group_ids.to_a
      criteria.and(:group_ids.in => group_ids).each do |route|
        ret << [ route.name, route.id ]
      end
      ret
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end

  def pull_up_options
    %w(enabled disabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
  end

  def on_remand_options
    %w(back_to_init back_to_previous).map { |v| [I18n.t("workflow.options.on_remand.#{v}"), v] }
  end

  alias approver_attachment_use_options pull_up_options
  alias circulation_attachment_use_options pull_up_options

  def levels
    approvers.map { |h| h[:level] }.uniq.compact.sort
  end

  def approvers_at(level)
    approvers.select { |h| level == h[:level] }
  end

  def approver_users_at(level)
    approvers_at(level).map { |h| self.class.approver_user_class.where(id: h[:user_id]).first }
  end

  def approver_user_editable?(level, user)
    h = approvers_at(level).find { |h| user.id == h[:user_id] }
    return if h.blank?
    editable = h[:editable]
    return if editable.blank?
    editable.to_i > 0
  end

  def required_count_at(level)
    self.required_counts[level - 1] || false
  end

  def required_count_label_at(level)
    required_count = required_count_at(level)
    case required_count
    when false then
      I18n.t("workflow.required_count_label.all")
    else
      I18n.t("workflow.required_count_label.minimum", required_count: required_count)
    end
  end

  def required_count_options
    ret = [ [ I18n.t("workflow.options.required_count.all"), false ] ]
    5.downto(1) do |required_count|
      ret << [ I18n.t("workflow.options.required_count.minimum", required_count: required_count), required_count ]
    end
    ret
  end

  def circulation_users_at(level)
    user_ids = circulations.select{ |h| h[:level] == level }.map { |h| h[:user_id] }
    self.class.approver_user_class.in(id: user_ids)
  end

  def approver_attachment_use_at(level)
    return if approver_attachment_uses.blank?

    index = level - 1
    return if index < 0 || approver_attachment_uses.length <= index

    approver_attachment_uses[index]
  end

  def approver_attachment_enabled_at?(level)
    approver_attachment_use_at(level) == "enabled"
  end

  def circulation_attachment_use_at(level)
    return if circulation_attachment_uses.blank?

    index = level - 1
    return if index < 0 || circulation_attachment_uses.length <= index

    circulation_attachment_uses[index]
  end

  def circulation_attachment_enabled_at?(level)
    circulation_attachment_use_at(level) == "enabled"
  end

  private

  def validate_approvers_presence
    errors.add :approvers, :blank if approvers.blank?
    approvers.each do |approver|
      errors.add :base, :approvers_level_blank if approver[:level].blank?
      if approver[:user_id].blank?
        errors.add :base, :approvers_user_id_blank
      elsif self.class.approver_user_class.where(id: approver[:user_id]).first.blank?
        errors.add :base, :approvers_user_missing
      end
    end
  end

  def validate_approvers_consecutiveness
    # level must start from 1 and level must be consecutive.
    max_level = levels.max
    return unless max_level

    1.upto(max_level) do |level|
      errors.add :base, :approvers_level_missing, level: level unless levels.include?(level)
    end
  end

  def validate_required_counts
    errors.add :required_counts, :blank if required_counts.blank?

    levels.each do |level|
      required_count = required_count_at(level)
      next if required_count == false

      approvers = approvers_at(level).to_a
      errors.add :required_counts, :required_count_greater_than_approvers, level: level, required_count: required_count \
        if approvers.length < required_count
    end
  end

  def validate_groups
    self.errors.add :group_ids, :blank if groups.blank?
  end

  def validate_approver_attachment_uses
    return if approver_attachment_uses.blank?
    if !approver_attachment_uses.all? { |v| v.blank? || %w(enabled disabled).include?(v) }
      errors.add :approver_attachment_uses, :invalid
    end
  end

  def validate_circulation_attachment_uses
    return if circulation_attachment_uses.blank?
    if !circulation_attachment_uses.all? { |v| v.blank? || %w(enabled disabled).include?(v) }
      errors.add :approver_attachment_uses, :invalid
    end
  end
end
