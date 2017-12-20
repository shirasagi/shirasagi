module Gws::Addon::Member
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    class_variable_set(:@@_keep_members_order, nil)
    class_variable_set(:@@_member_include_custom_groups, nil)
    class_variable_set(:@@_member_ids_required, true)

    embeds_ids :members, class_name: "Gws::User"
    embeds_ids :member_custom_groups, class_name: "Gws::CustomGroup"

    permit_params member_ids: [], member_custom_group_ids: []

    before_validation :validate_member_ids, if: -> { member_ids.present? }

    validate :validate_presence_member

    scope :member, ->(user, opts = {}) {
      or_cond = [{ member_ids: user.id }]
      if member_include_custom_groups?
        or_cond << { :member_custom_group_ids.in => Gws::CustomGroup.member(user).map(&:id) }
      end

      or_cond << allow_condition(:read, user, site: opts[:site]) if opts[:include_role]
      self.and([{ '$or' => or_cond }])
    }
  end

  def member?(user, opts = {})
    return true if member_ids.include?(user.id)
    if self.class.member_include_custom_groups?
      return true if (member_custom_group_ids & Gws::CustomGroup.member(user).map(&:id)).present?
    end
    if opts[:include_role]
      if opts[:strict]
        return allowed?(:read, user, site: opts[:site] || site, strict: true)
      else
        return allowed?(:read, user, site: opts[:site] || site) # valid role
      end
    end
    false
  end

  def sorted_members
    return members.order_by_title(site || cur_site) unless self.class.keep_members_order?
    return @sorted_members if @sorted_members

    hash = members.map { |m| [m.id, m] }.to_h
    @sorted_members = member_ids.map { |id| hash[id] }.compact
  end

  def sorted_overall_members
    member_ids = member_custom_groups.pluck(:member_ids).flatten
    member_ids += self.member_ids
    member_ids.compact!
    member_ids.uniq!

    members = Gws::User.in(id: member_ids)

    return members.order_by_title(site || cur_site) unless self.class.keep_members_order?
    return @sorted_members if @sorted_members

    hash = members.map { |m| [m.id, m] }.to_h
    @sorted_members = member_ids.map { |id| hash[id] }.compact
  end

  def sorted_overall_members_was
    member_ids = Gws::CustomGroup.site(site || cur_site).in(id: member_custom_group_ids_was).pluck(:member_ids).flatten
    member_ids += self.member_ids_was.to_a
    member_ids.compact!
    member_ids.uniq!

    members = Gws::User.in(id: member_ids)

    return members.order_by_title(site || cur_site) unless self.class.keep_members_order?
    return @sorted_members if @sorted_members

    hash = members.map { |m| [m.id, m] }.to_h
    @sorted_members = member_ids.map { |id| hash[id] }.compact
  end

  private

  def validate_member_ids
    self.member_ids = member_ids.uniq
  end

  def validate_presence_member
    return true unless self.class.member_ids_required?
    return true if member_ids.present?
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
