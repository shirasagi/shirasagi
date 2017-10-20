module Gws::Addon::Monitor::Group
  extend ActiveSupport::Concern
  extend SS::Addon

  included do

    embeds_ids :attend_groups, class_name: "Gws::Group"
    permit_params attend_group_ids: []
    before_validation :validate_attend_group_ids, if: -> { attend_group_ids.present? }

    scope :group, ->(group) {
      cond = [{ group_ids: group.id }]
      self.and([{ '$or' => cond }])
    }
  end

  def group?(group)
    return true if attend_group_ids.include?(group.id)
    false
  end

  def sorted_groups
    return groups.order_by_title(site || cur_site) unless self.class.keep_groups_order?
    return @sorted_groups if @sorted_groups

    hash = groups.map { |g| [g.id, g] }.to_h
    @sorted_groups = attend_group_ids.map { |id| hash[id] }.compact
  end

  def sorted_overall_groups
    attend_group_ids += self.attend_group_ids
    attend_group_ids.compact!
    attend_group_ids.uniq!

    groups = Gws::Group.in(id: attend_group_ids)

    return groups.order_by_title(site || cur_site) unless self.class.keep_groups_order?
    return @sorted_groups if @sorted_groups

    hash = groups.map { |g| [g.id, g] }.to_h
    @sorted_groups = attend_group_ids.map { |id| hash[id] }.compact
  end

  private

  def validate_attend_group_ids
    self.attend_group_ids = attend_group_ids.uniq
  end

  def validate_presence_group
    return true if attend_group_ids.present?
    errors.add :attend_group_ids, :empty
  end

  module ClassMethods
    def keep_groups_order?
      class_variable_get(:@@_keep_groups_order)
    end

    private

    def keep_groups_order
      class_variable_set(:@@_keep_groups_order, true)
    end

  end
end
