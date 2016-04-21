module Gws::Addon::Facility::ReservableSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :reservable_groups_hash, type: Hash
    field :reservable_members_hash, type: Hash

    embeds_ids :reservable_groups, class_name: "Gws::Group"
    embeds_ids :reservable_members, class_name: "Gws::User"

    permit_params reservable_group_ids: [], reservable_member_ids: []

    before_validation :set_reservable_groups_hash
    before_validation :set_reservable_members_hash

    scope :reservable, ->(user) {
      where("$and" => [{ "$or" => [
        { "reservable_group_ids.0" => { "$exists" => false }, "reservable_member_ids.0" => { "$exists" => false } },
        { :reservable_group_ids.in => user.group_ids },
        { reservable_member_ids: user.id }
      ]}])
    }
  end

  def reservable_setting_present?
    return true if reservable_group_ids.present?
    return true if reservable_member_ids.present?
    false
  end

  def reservable?(user)
    return true if reservable_group_ids.blank? && reservable_member_ids.blank?
    return true if reservable_group_ids.any? {|m| user.group_ids.include?(m) }
    return true if reservable_member_ids.include?(user.id)
    false
  end

  def reservable_groups_hash
    self[:reservable_groups_hash].presence || reservable_groups.map { |m| [m.id, m.name] }.to_h
  end

  def reservable_group_names
    reservable_groups_hash.values
  end

  def reservable_members_hash
    self[:reservable_members_hash].presence || reservable_members.map { |m| [m.id, m.long_name] }.to_h
  end

  def reservable_member_names
    reservable_members_hash.values
  end

  private
    def set_reservable_groups_hash
      self.reservable_groups_hash = reservable_groups.map { |m| [m.id, m.name] }.to_h
    end

    def set_reservable_members_hash
      self.reservable_members_hash = reservable_members.map { |m| [m.id, m.long_name] }.to_h
    end
end
