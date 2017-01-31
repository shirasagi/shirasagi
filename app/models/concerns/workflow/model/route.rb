module Workflow::Model::Route
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  included do
    store_in collection: "workflow_routes"

    cattr_reader(:approver_user_class) { Cms::User }

    seqid :id
    field :name, type: String
    embeds_ids :groups, class_name: "SS::Group"
    field :approvers, type: Workflow::Extensions::Route::Approvers
    field :required_counts, type: Workflow::Extensions::Route::RequiredCounts
    permit_params :name, group_ids: [], approvers: [], required_counts: []

    validates :name, presence: true, length: { maximum: 40 }
    validate :validate_approvers_presence
    validate :validate_approvers_consecutiveness
    validate :validate_required_counts
    validate :validate_groups

    default_scope ->{ order_by name: 1 }
  end

  module ClassMethods
    def route_options(user)
      ret = [ [ t("my_group"), "my_group" ] ]
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

  def levels
    approvers.map { |h| h[:level] }.uniq.compact.sort
  end

  def approvers_at(level)
    approvers.select { |h| level == h[:level] }
  end

  def approver_users_at(level)
    approvers_at(level).map { |h| self.class.approver_user_class.where(id: h[:user_id]).first }
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
end
