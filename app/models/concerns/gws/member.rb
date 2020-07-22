module Gws::Member
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    class_variable_set(:@@_keep_members_order, nil)
    class_variable_set(:@@_member_include_custom_groups, nil)
    class_variable_set(:@@_member_ids_required, true)

    embeds_ids :members, class_name: "Gws::User"
    embeds_ids :member_groups, class_name: "Gws::Group"
    embeds_ids :member_custom_groups, class_name: "Gws::CustomGroup"

    permit_params member_ids: [], member_group_ids: [], member_custom_group_ids: []

    before_validation :validate_member_ids, if: -> { member_ids.present? }

    validate :validate_presence_member

    scope :member, ->(user) {
      or_conds = member_conditions(user)
      self.and([{ '$or' => or_conds }])
    }
    scope :not_member, ->(user) {
      and_conds = member_conditions(user, negate: true)
      self.and(and_conds)
    }
    scope :any_members, ->(users) {
      or_conds = []
      users.each do |user|
        or_conds += member_conditions(user)
      end
      self.and([{ '$or' => or_conds }])
    }
  end

  def member?(user)
    return true if member_ids.include?(user.id)
    return true if user.group_ids.any? { |group_id| member_group_ids.include?(group_id) }
    if self.class.member_include_custom_groups?
      return true if (member_custom_group_ids & Gws::CustomGroup.member(user).pluck(:id)).present?
    end
    false
  end

  def sorted_members
    return members.order_by_title(site || cur_site) unless self.class.keep_members_order?
    return @sorted_members if @sorted_members

    hash = members.map { |m| [m.id, m] }.to_h
    @sorted_members = member_ids.map { |id| hash[id] }.compact
  end

  def overall_members
    user_ids = members.pluck(:id)
    group_ids = member_groups.active.pluck(:id)

    if self.class.member_include_custom_groups?
      user_ids += member_custom_groups.pluck(:member_ids).flatten
      group_ids += member_custom_groups.pluck(:member_group_ids).flatten
    end

    group_ids.compact!
    group_ids.uniq!
    group_ids += Gws::Group.site(@cur_site || site).in(id: group_ids).active.pluck(:id)

    user_ids += Gws::User.in(group_ids: group_ids).pluck(:id)
    user_ids.compact!
    user_ids.uniq!
    Gws::User.in(id: user_ids)
  end

  def sorted_overall_members
    overall_members.active.order_by_title(site || cur_site)
  end

  def overall_members_was
    user_ids = member_ids_was.to_a
    group_ids = member_group_ids_was.to_a

    if self.class.member_include_custom_groups?
      member_custom_groups_was = Gws::CustomGroup.site(site || cur_site).in(id: member_custom_group_ids_was)
      user_ids += member_custom_groups_was.pluck(:member_ids).flatten
      group_ids += member_custom_groups_was.pluck(:member_group_ids).flatten
    end

    group_ids.compact!
    group_ids.uniq!
    group_ids += Gws::Group.site(@cur_site || site).in(id: group_ids).active.pluck(:id)

    user_ids += Gws::User.in(group_ids: group_ids).pluck(:id)
    user_ids.compact!
    user_ids.uniq!
    Gws::User.in(id: user_ids)
  end

  def sorted_overall_members_was
    overall_members_was.active.order_by_title(site || cur_site)
  end

  private

  def validate_member_ids
    self.member_ids = member_ids.uniq
  end

  def validate_presence_member
    return true unless self.class.member_ids_required?
    return true if member_ids.present?
    return true if member_group_ids.present?
    return true if self.class.member_include_custom_groups? && member_custom_group_ids.present?
    errors.add :member_ids, :empty
  end

  module ClassMethods
    def keep_members_order?
      class_variable_get(:@@_keep_members_order)
    end

    def member_include_custom_groups?
      class_variable_get(:@@_member_include_custom_groups)
    end

    def member_ids_required?
      class_variable_get(:@@_member_ids_required)
    end

    def member_conditions(user, options = {})
      or_conds = [{ member_ids: options[:negate] ? { "$ne" => user.id } : user.id }]

      in_criteria = { "$in" => user.group_ids }
      or_conds << { member_group_ids: options[:negate] ? { "$not" => in_criteria } : in_criteria }

      if member_include_custom_groups?
        custom_group_ids = Gws::CustomGroup.member(user).pluck(:id)
        if custom_group_ids.present?
          in_criteria = { "$in" => custom_group_ids }
          or_conds << { member_custom_group_ids: options[:negate] ? { "$not" => in_criteria } : in_criteria }
        end
      end
      or_conds
    end

    private

    def keep_members_order
      class_variable_set(:@@_keep_members_order, true)
    end

    def member_include_custom_groups
      class_variable_set(:@@_member_include_custom_groups, true)
    end

    def member_ids_optional
      class_variable_set(:@@_member_ids_required, false)
    end
  end
end
