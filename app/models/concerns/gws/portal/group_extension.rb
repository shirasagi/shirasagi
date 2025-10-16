module Gws::Portal::GroupExtension
  extend ActiveSupport::Concern

  included do
    has_many :portal_setting, class_name: 'Gws::Portal::GroupSetting',
      foreign_key: :portal_group_id, dependent: :destroy, inverse_of: :portal_group
  end

  def find_portal_setting(overwrite_params = {})
    site = overwrite_params[:cur_site]
    portal = portal_setting.site(site).first
    portal ||= Gws::Portal::GroupSetting.build_new_setting(self, site: site)
    portal.attributes = overwrite_params
    portal
  end
end
