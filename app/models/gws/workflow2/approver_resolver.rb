class Gws::Workflow2::ApproverResolver
  include ActiveModel::Model

  class Result
    include ActiveModel::Model

    attr_accessor :level, :user_type, :user, :editable, :file_ids, :error

    # level と user_type は必須、user, editable, file_ids, error は省略可
    def initialize(level:, user_type:, **options)
      super()
      self.level = level
      self.user_type = user_type
      self.attributes = options
    end

    class << self
      def from_hash(approver_hash)
        new(
          level: approver_hash['level'].to_i, user_type: approver_hash['user_type'],
          user: approver_hash['user'], editable: approver_hash['editable'])
      end
    end

    def to_h
      hash = { level: level, user_type: user_type }
      if user
        if user_type == "special"
          hash[:user] = user
        else
          hash[:user_id] = user.id
          hash[:user] = user
        end
      end
      if editable
        hash[:editable] = 1
      end
      if file_ids
        hash[:file_ids] = file_ids
      end
      if error
        hash[:error] = error
      end
      hash
    end
  end

  USER_FIELDS = %i[
    id name uid email organization_uid title_ids title_orders occupation_ids
    group_ids gws_default_group_ids gws_main_group_ids updated
  ].freeze
  GROUP_FIELDS = %i[
    id name superior_user_ids
  ].freeze
  PERMIT_PARAMS = [
    workflow_approvers: %i[level editable user_type user_id].freeze,
    workflow_circulations: %i[level user_type user_id].freeze,
  ].freeze

  attr_accessor :cur_site, :cur_group, :cur_user, :route, :item, :workflow_approvers, :workflow_circulations
  attr_reader :resolved_approvers, :resolved_circulations

  def resolve
    case route
    when :restart
      resolve_restart
    when :my_group
      resolve_my_group
    when :my_group_alternate
      resolve_my_group_alternate
    when Gws::Workflow::Route, Gws::Workflow2::Route
      resolve_route
    end

    item.workflow_pull_up = @workflow_pull_up
    item.workflow_on_remand = @workflow_on_remand
    item.workflow_approvers = @resolved_approvers.map(&:to_h)
    item.workflow_required_counts = @workflow_required_counts
    item.workflow_approver_attachment_uses = @workflow_approver_attachment_uses
    item.workflow_circulations = @resolved_circulations.map(&:to_h)
    item.workflow_circulation_attachment_uses = @workflow_circulation_attachment_uses
  end

  private

  def resolve_restart
    # rubocop:disable Rails/Pluck
    user_ids = item.workflow_approvers.map { |approver_hash| approver_hash[:user_id] }
    user_ids += item.workflow_circulations.map { |circulation_hash| circulation_hash[:user_id] }
    # rubocop:enable Rails/Pluck
    user_ids.uniq!
    user_ids.compact!
    # warm-up cache
    find_users(user_ids)

    @workflow_pull_up = item.workflow_pull_up
    @workflow_on_remand = item.workflow_on_remand
    @resolved_approvers = restart_approvers
    @workflow_required_counts = item.workflow_required_counts
    @workflow_approver_attachment_uses = item.workflow_approver_attachment_uses
    @resolved_circulations = restart_circulations
    @workflow_circulation_attachment_uses = item.workflow_circulation_attachment_uses
  end

  def resolve_my_group
    @workflow_pull_up = "disabled"
    @workflow_on_remand = "back_to_init"
    @resolved_approvers = superior_results(1, type: :approver, adds_error: true)
    @workflow_required_counts = [ false ]
    @workflow_approver_attachment_uses = %w(disabled)
    @resolved_circulations = []
    @workflow_circulation_attachment_uses = []
  end

  def resolve_my_group_alternate
    resolve_my_group
    @workflow_required_counts = [ 1 ]
  end

  def resolve_route
    @workflow_pull_up = route.pull_up
    @workflow_on_remand = route.on_remand
    @resolved_approvers = []
    @workflow_required_counts = route.required_counts
    @workflow_approver_attachment_uses = route.approver_attachment_uses

    @resolved_circulations = []
    @workflow_circulation_attachment_uses = route.circulation_attachment_uses

    route.levels.each do |level|
      resolve_approvers level, route.approvers_at(level)
    end
    1.upto(route.class::MAX_CIRCULATIONS).each do |level|
      circulations = route.circulations_at(level)
      next if circulations.blank?

      resolve_circulations level, circulations
    end
  end

  def find_user(user_id)
    @id_user_map ||= {}

    user_id = user_id.to_i if user_id.numeric?
    return @id_user_map[user_id] if @id_user_map.key?(user_id)

    criteria = Gws::User.all
    criteria = criteria.site(cur_site)
    criteria = criteria.active
    criteria = criteria.readable_users(cur_user, site: cur_site)
    criteria = criteria.only(*USER_FIELDS)
    criteria = criteria.where(id: user_id)
    @id_user_map[user_id] = criteria.first
  end

  def find_users(user_ids)
    @id_user_map ||= {}

    rejected_user_ids = user_ids.reject { |user_id| @id_user_map.key?(user_id) }
    if rejected_user_ids.present?
      criteria = Gws::User.all
      criteria = criteria.site(cur_site)
      criteria = criteria.active
      criteria = criteria.readable_users(cur_user, site: cur_site)
      criteria = criteria.only(*USER_FIELDS)
      criteria = criteria.in(id: rejected_user_ids)
      criteria.to_a.each do |user|
        @id_user_map[user.id] = user
      end
    end

    user_ids.map { |user_id| @id_user_map[user_id] }.compact
  end

  def cur_group_users
    @group_users ||= begin
      criteria = Gws::User.all
      criteria = criteria.site(cur_site)
      criteria = criteria.active
      criteria = criteria.readable_users(cur_user, site: cur_site)
      criteria = criteria.only(*USER_FIELDS)
      criteria = criteria.where(group_ids: cur_group.id)
      criteria.to_a
    end
  end

  def all_groups
    @all_groups ||= begin
      criteria = Gws::Group.all
      criteria = criteria.site(cur_site)
      criteria = criteria.active
      criteria = criteria.only(*GROUP_FIELDS)
      criteria.to_a
    end
  end

  def id_group_map
    @id_group_map ||= all_groups.index_by(&:id)
  end

  def find_gws_default_group(user)
    return if user.gws_default_group_ids.blank?

    group_id = user.gws_default_group_ids[cur_site.id.to_s]
    return if group_id.blank?

    group_id = group_id.to_i if group_id.numeric? # for backwards compatibility
    id_group_map[group_id]
  end

  def find_gws_main_group(user)
    return if user.gws_main_group_ids.blank?

    group_id = user.gws_main_group_ids[cur_site.id.to_s]
    return if group_id.blank?

    group_id = group_id.to_i if group_id.numeric? # for backwards compatibility
    id_group_map[group_id]
  end

  def all_titles
    @all_titles ||= Gws::UserTitle.all.site(@cur_site).only(:id, :name).to_a
  end

  def id_title_map
    @id_title_map ||= all_titles.index_by(&:id)
  end

  def all_occupations
    @all_occupations ||= Gws::UserOccupation.all.site(@cur_site).only(:id, :name).to_a
  end

  def id_occupation_map
    @id_occupation_map ||= all_occupations.index_by(&:id)
  end

  def editable?(value)
    value == 1
  end

  def workflow_approvers_at(level)
    return [] if level.nil? || @resolved_approvers.blank?
    @resolved_approvers.select { |approver_result| approver_result.level == level }
  end

  def workflow_circulations_at(level)
    return [] if level.nil? || @resolved_circulations.blank?
    @resolved_circulations.select { |circulation_result| circulation_result.level == level }
  end

  def restart_approvers
    item.workflow_approvers.map do |approver_hash|
      user = find_user(approver_hash[:user_id])
      if user
        Result.new(
          level: approver_hash[:level], user_type: Gws::User.name,
          user: user, editable: editable?(approver_hash[:editable]), file_ids: approver_hash[:file_ids])
      else
        error = I18n.t("gws/workflow2.errors.messages.approver_is_deleted")
        Result.new(level: approver_hash[:level], user_type: Gws::User.name, error: error)
      end
    end
  end

  def restart_circulations
    item.workflow_circulations.map do |circulation_hash|
      user = find_user(circulation_hash[:user_id])
      if user
        Result.new(level: circulation_hash[:level], user_type: Gws::User.name, user: user)
      else
        error = I18n.t("gws/workflow2.errors.messages.circulator_is_deleted")
        Result.new(level: circulation_hash[:level], user_type: Gws::User.name, error: error)
      end
    end
  end

  def resolve_approvers(level, approver_hashes)
    approver_results = []
    approver_hashes.each do |approver_hash|
      resolved = resolve_approver(level, approver_hash)
      approver_results += resolved if resolved
    end
    approver_results.flatten!

    if workflow_approvers.present?
      approver_results = resolve_specials(level, workflow_approvers, approver_results)
    end

    @resolved_approvers += approver_results
  end

  def resolve_approver(level, approver_hash)
    case approver_hash[:user_type]
    when "superior"
      superior_results(level, type: :approver, editable: editable?(approver_hash[:editable]))
    when Gws::UserTitle.name
      title_results(level, approver_hash[:user_id], editable: editable?(approver_hash[:editable]))
    when Gws::UserOccupation.name
      occupation_results(level, approver_hash[:user_id], editable: editable?(approver_hash[:editable]))
    when Gws::User.name
      user_results(level, approver_hash[:user_id], editable: editable?(approver_hash[:editable]))
    when "special"
      special_results(level, approver_hash[:user_id], editable: editable?(approver_hash[:editable]))
    end
  end

  def resolve_circulations(level, circulation_hashes)
    circulation_results = []
    circulation_hashes.each do |circulation_hash|
      resolved = resolve_circulation level, circulation_hash
      circulation_results += resolved if resolved
    end
    circulation_results.flatten!

    if workflow_circulations.present?
      circulation_results = resolve_specials(level, workflow_circulations, circulation_results)
    end

    @resolved_circulations += circulation_results
  end

  def resolve_circulation(level, circulation_hash)
    case circulation_hash[:user_type]
    when "superior"
      superior_results(level, type: :circulation)
    when Gws::UserTitle.name
      title_results(level, circulation_hash[:user_id])
    when Gws::UserOccupation.name
      occupation_results(level, circulation_hash[:user_id])
    when Gws::User.name
      user_results(level, circulation_hash[:user_id])
    when "special"
      special_results(level, circulation_hash[:user_id])
    end
  end

  def resolve_specials(level, source_hashes, approver_results)
    selected_specials = source_hashes.filter_map do |approver_hash|
      next if approver_hash['level'].to_i != level

      user = find_user(approver_hash['user_id'])
      next unless user

      approver_hash['user'] = user
      approver_hash
    end
    approver_results.delete_if { |approver_result| approver_result.user_type == 'special' }
    if selected_specials.present?
      approver_results += selected_specials.map { |approver_hash| Result.from_hash(approver_hash) }
    end
    approver_results
  end

  def superior_results(level, type:, editable: nil, adds_error: true)
    if level == 1
      return superior_results_level1(level, editable: editable, adds_error: adds_error)
    end

    superior_results_level_n(level, type: type, editable: editable, adds_error: adds_error)
  end

  def special_results(level, user_id, editable: nil)
    [ Result.new(level: level, user_type: "special", user: user_id, editable: editable) ]
  end

  # 上位ユーザー at level 1
  # level 1 の場合、ユーザーの上位ユーザーを選択する
  def superior_results_level1(level, editable: nil, adds_error: true)
    if cur_group.superior_user_ids.blank?
      if adds_error
        error = I18n.t("gws/workflow2.errors.messages.superior_is_not_found")
        return [ Result.new(level: level, user_type: "superior", error: error) ]
      else
        return []
      end
    end

    users = find_users(cur_group.superior_user_ids)
    if users.blank?
      if adds_error
        error = I18n.t("gws/workflow2.errors.messages.superior_is_not_found")
        return [ Result.new(level: level, user_type: "superior", error: error) ]
      else
        return []
      end
    end

    users.map do |user|
      Result.new(level: level, user_type: "superior", user: user, editable: editable)
    end
  end

  def find_superiors_at(type, level)
    case type
    when :approver
      results = workflow_approvers_at(level)
    when :circulation
      results = workflow_circulations_at(level)
    end
    return if results.blank?

    results.select { |result| result.user_type == "superior" && result.user }.map { |result| result.user }
  end

  def find_superior(superior_user)
    group = find_gws_default_group(superior_user)
    if group.present? && group.superior_user_ids.present? && (users = find_users(group.superior_user_ids)).present?
      return Gws::User.order_users_by_title(users, cur_site: cur_site).first
    end

    group = find_gws_main_group(superior_user)
    if group.present? && group.superior_user_ids.present? && (users = find_users(group.superior_user_ids)).present?
      return Gws::User.order_users_by_title(users, cur_site: cur_site).first
    end

    superior_user.group_ids.each do |group_id|
      group = id_group_map[group_id]
      next if group.blank? || group.superior_user_ids.blank?

      users = find_users(group.superior_user_ids)
      next if users.blank?

      return Gws::User.order_users_by_title(users, cur_site: cur_site).first
    end
  end

  # 上位ユーザー above level 2
  # level 2 以上の場合、下位レベルの上位ユーザーの上位ユーザーを選択する
  def superior_results_level_n(level, type:, editable: nil, adds_error: true)
    lower_level_superiors = find_superiors_at(type, level - 1)
    if lower_level_superiors.blank?
      error = I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
      return [ Result.new(level: level, user_type: "superior", error: error) ]
    end

    ret = []
    lower_level_superiors.each do |lower_level_superior|
      superior = find_superior(lower_level_superior)
      next unless superior

      ret << Result.new(level: level, user_type: "superior", user: superior, editable: editable)
    end
    if ret.blank?
      error = I18n.t("gws/workflow2.errors.messages.lower_level_superior_is_not_set")
      ret << Result.new(level: level, user_type: "superior", error: error)
    end

    ret
  end

  def title_results(level, user_id, editable: nil)
    title = id_title_map[user_id]
    if title.blank?
      error = I18n.t("gws/workflow2.errors.messages.user_title_is_not_found")
      return [ Result.new(level: level, user_type: Gws::UserTitle.name, error: error) ]
    end

    users = cur_group_users.select { |user| user.title_ids.include?(title.id) }
    users.compact!
    if users.blank?
      error = I18n.t("gws/workflow2.errors.messages.user_whos_title_is_not_found", title_name: title.name)
      return [ Result.new(level: level, user_type: Gws::UserTitle.name, error: error) ]
    end

    users.map do |user|
      Result.new(level: level, user_type: Gws::UserTitle.name, user: user, editable: editable)
    end
  end

  def occupation_results(level, user_id, editable: nil)
    occupation = id_occupation_map[user_id]
    if occupation.blank?
      error = I18n.t("gws/workflow2.errors.messages.user_occupation_is_not_found")
      return [ Result.new(level: level, user_type: Gws::UserOccupation.name, error: error) ]
    end

    users = cur_group_users.select { |user| user.occupation_ids.include?(occupation.id) }
    users.compact!

    if users.blank?
      error = I18n.t("gws/workflow2.errors.messages.user_whos_occupation_is_not_found", occupation_name: occupation.name)
      return [ Result.new(level: level, user_type: Gws::UserOccupation.name, error: error) ]
    end

    users.map do |user|
      Result.new(level: level, user_type: Gws::UserOccupation.name, user: user, editable: editable)
    end
  end

  def user_results(level, user_id, editable: nil)
    user = find_user(user_id)
    if user.blank?
      error = I18n.t("gws/workflow2.errors.messages.user_is_not_found")
      return [ Result.new(level: level, user_type: Gws::User.name, error: error) ]
    end

    [ Result.new(level: level, user_type: Gws::User.name, user: user, editable: editable) ]
  end
end
