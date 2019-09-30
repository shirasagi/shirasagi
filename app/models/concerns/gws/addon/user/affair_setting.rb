module Gws::Addon::User::AffairSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :staff_category, type: String, default: "regular_staff"
    permit_params :staff_category

    field :staff_address_uid, type: String
    permit_params :staff_address_uid

    embeds_ids :superior_groups, class_name: "Gws::Group"
    embeds_ids :superior_users, class_name: "Gws::User"

    permit_params superior_group_ids: []
    permit_params superior_user_ids: []
  end

  def staff_category_options
    I18n.t("gws/affair.options.staff_category").map { |k, v| [v, k] }
  end

  def group_code(site)
    return nil if site.nil?

    group = gws_main_group(site)
    return nil if group.nil?

    groups = []
    groups << group
    groups += group.parents.to_a.sort_by { |item| -1 * item.name.size }
    return nil if groups.blank?

    groups.map { |g| g.group_code }.select(&:present?).first
  end

  def target_user_code(site)
    [
      id.to_s,
      staff_address_uid.to_s,
      group_code(site).to_s
    ].join("_")
  end

  def gws_superior_users
    items = superior_users.to_a
    return items if items.present?

    items = groups.map { |item| item.gws_superior_users.to_a }.flatten
    items.uniq { |item| item.id }
  end

  def gws_superior_groups
    items = superior_groups.to_a
    return items if items.present?

    items = groups.map { |item| item.gws_superior_groups.to_a }.flatten
    items.uniq { |item| item.id }
  end
end
