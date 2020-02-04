module Gws::Portal::GroupExtension
  extend ActiveSupport::Concern

  included do
    has_many :portal_setting, class_name: 'Gws::Portal::GroupSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group
  end

  def find_portal_setting(overwrite_params = {})
    site = overwrite_params[:cur_site]
    portal = portal_setting.site(site).first_or_initialize(
      name: organization? ? I18n.t("gws/portal.tabs.root_portal") : trailing_name.truncate(20),
      readable_setting_range: organization? ? "public" : "select",
      readable_group_ids: organization? ? [] : [id],
      group_ids: [id]
    )
    portal.attributes = overwrite_params
    portal
  end
end
