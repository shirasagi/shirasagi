class Gws::Workflow2::Route
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workflow2::ApproverView
  include Gws::Addon::Workflow2::CirculationView
  include Gws::Addon::Workflow2::RouteReadableSetting
  include Gws::Addon::Workflow2::RouteGroupPermission
  include Gws::Addon::History

  MAX_NAME_LENGTH = 40
  MAX_APPROVERS = 5
  MAX_CIRCULATIONS = 3

  no_needs_read_permission_to_read

  cattr_reader(:approver_user_class) { Gws::User }

  field :name, type: String
  field :pull_up, type: String
  field :on_remand, type: String
  field :approvers, type: Workflow::Extensions::Route::Approvers
  field :required_counts, type: Workflow::Extensions::Route::RequiredCounts
  field :approver_attachment_uses, type: Array
  field :circulations, type: Workflow::Extensions::Route::Circulations
  field :circulation_attachment_uses, type: Array
  field :remark, type: String

  permit_params :name, :pull_up, :on_remand, :remark
  permit_params approvers: [ :level, :user_type, :user_id, :editable ], required_counts: [], approver_attachment_uses: []
  permit_params circulations: [ :level, :user_type, :user_id ], circulation_attachment_uses: []

  before_validation :normalize_approvers
  before_validation :normalize_circulations

  validates :name, presence: true, length: { maximum: MAX_NAME_LENGTH }
  validates :pull_up, inclusion: { in: %w(enabled disabled), allow_blank: true }
  validates :on_remand, inclusion: { in: %w(back_to_init back_to_previous), allow_blank: true }
  validate :validate_approvers_presence
  validate :validate_approvers_consecutiveness
  validate :validate_required_counts
  validate :validate_approver_attachment_uses
  validate :validate_circulation_attachment_uses

  class << self
    def new_from_route(source_route)
      ret = ::Mongoid::Factory.from_db(self, source_route.attributes)

      # インスタンス編集を直接操作し new_record? が true になるように調整する
      ret.instance_variable_set(:@new_record, true)
      ret.instance_variable_set(:@destroyed, false)

      # 新規作成時には未設定の属性に nil をセット
      ret.id = nil
      ret.updated = nil
      ret.created = nil
      ret.user_ids = nil
      ret.group_ids = nil

      # 名前に "[複製]" をつける
      ret.name = "[#{I18n.t("workflow.cloned_name_prefix")}] #{source_route.name}"

      ret
    end

    def route_options(user, cur_site:, item: nil, public_only: false, selected: nil)
      ret = []
      if item.present? && item.workflow_approvers.present? && item.requested.present?
        ret << [ I18n.t("workflow.restart_workflow"), "restart" ]
      end
      unless SS.config.workflow.disable_my_group
        ret << [ t("my_group"), "my_group" ]
        ret << [ t("my_group_alternate"), "my_group_alternate" ]
      end

      routes = all.site(cur_site)
      if public_only
        routes = routes.where(readable_setting_range: 'public')
      else
        routes = routes.readable(user)
      end
      routes.only(:id, :name).each do |route|
        ret << [ route.name, route.id.to_s ]
      end

      if selected && BSON::ObjectId.legal?(selected) && ret.none? { |_name, route_id| route_id == selected }
        selected_route = Gws::Workflow2::Route.site(cur_site).find(selected) rescue nil
        if selected_route
          ret << [ selected_route.name, selected ]
        end
      end

      ret
    end

    def search(params)
      all.search_name(params).search_keyword(params)
    end

    def search_name(params)
      return all if params.blank? || params[:name].blank?
      all.keyword_in params[:name], :name
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in params[:keyword], :name, :remark
    end

    def required_count_options
      ret = [ [ I18n.t("workflow.options.required_count.all"), false ] ]
      5.downto(1) do |required_count|
        ret << [ I18n.t("workflow.options.required_count.minimum", required_count: required_count), required_count ]
      end
      ret
    end

    def pull_up_options
      %w(enabled disabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    alias approver_attachment_use_options pull_up_options
    alias circulation_attachment_use_options pull_up_options
  end

  delegate :pull_up_options, to: :class

  def on_remand_options
    %w(back_to_init back_to_previous).map { |v| [I18n.t("workflow.options.on_remand.#{v}"), v] }
  end

  alias approver_attachment_use_options pull_up_options
  alias circulation_attachment_use_options pull_up_options

  # rubocop:disable Rails/Pluck
  def levels
    approvers.map { |h| h[:level] }.uniq.compact.sort
  end
  # rubocop:enable Rails/Pluck

  def approvers_at(level)
    approvers.select { |h| level == h[:level] }
  end

  def required_count_at(level)
    self.required_counts[level - 1] || false
  end

  def required_count_label_at(level)
    required_count = required_count_at(level)
    case required_count
    when false
      I18n.t("workflow.required_count_label.all")
    else
      I18n.t("workflow.required_count_label.minimum", required_count: required_count)
    end
  end

  delegate :required_count_options, to: :class

  def circulations_at(level)
    circulations.select { |h| h[:level] == level }
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

  def normalize_approvers
    return if self.approvers.blank?

    approvers = self.approvers
    approvers = approvers.dup
    approvers.reject! { |approver| approver.blank? || approver[:user_type].blank? || approver[:user_id].blank? }
    self.approvers = approvers
  end

  def normalize_circulations
    return if self.circulations.blank?

    circulations = self.circulations
    circulations = circulations.dup
    circulations.reject! { |circulator| circulator.blank? || circulator[:user_type].blank? || circulator[:user_id].blank? }
    self.circulations = circulations
  end

  def validate_approvers_presence
    errors.add :approvers, :blank if approvers.blank?
    approvers.each do |approver|
      if approver[:level].blank?
        errors.add :base, :approvers_level_blank
      end
      if approver[:user_id].blank?
        errors.add :base, :approvers_user_id_blank
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

  def validate_approver_attachment_uses
    return if approver_attachment_uses.blank?
    available_uses = %w(enabled disabled)
    if !approver_attachment_uses.all? { |v| v.blank? || available_uses.include?(v) }
      errors.add :approver_attachment_uses, :invalid
    end
  end

  def validate_circulation_attachment_uses
    return if circulation_attachment_uses.blank?
    available_uses = %w(enabled disabled)
    if !circulation_attachment_uses.all? { |v| v.blank? || available_uses.include?(v) }
      errors.add :approver_attachment_uses, :invalid
    end
  end
end
