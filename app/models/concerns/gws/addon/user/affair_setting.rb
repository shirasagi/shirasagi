module Gws::Addon::User::AffairSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    # 職員区分
    field :staff_category, type: String, default: "regular_staff"
    permit_params :staff_category

    # 宛名番号
    field :staff_address_uid, type: String
    permit_params :staff_address_uid
  end

  def staff_category_options
    I18n.t("gws/affair.options.staff_category").map { |k, v| [v, k] }
  end

  def target_group_id(site)
    return nil if site.nil?

    group = gws_main_group(site)
    return nil if group.nil?

    groups = []
    groups << group
    groups += group.parents.to_a.sort_by { |item| -1 * item.name.size }
    return nil if groups.blank?

    groups.map(&:id).select(&:present?).first
  end

  def target_user_code(site)
    [
      id.to_s,
      staff_address_uid.to_s,
      target_group_id(site).to_s
    ].join("_")
  end
end
