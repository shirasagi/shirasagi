module Gws::Portal::UserExtension
  extend ActiveSupport::Concern

  included do
    has_many :portal_setting, class_name: 'Gws::Portal::UserSetting',
      foreign_key: :portal_user_id, dependent: :destroy, inverse_of: :portal_user
  end

  def find_portal_setting(overwrite_params = {})
    site = overwrite_params[:cur_site]
    portal = portal_setting.site(site).first_or_initialize(
      name: long_name.truncate(20),
      readable_member_ids: [id],
      user_ids: [id]
    )
    portal.attributes = overwrite_params
    portal
  end
end
