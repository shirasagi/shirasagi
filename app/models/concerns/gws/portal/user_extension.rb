module Gws::Portal::UserExtension
  extend ActiveSupport::Concern

  included do
    has_many :portal_setting, class_name: 'Gws::Portal::UserSetting',
      foreign_key: :portal_user_id, dependent: :destroy, inverse_of: :portal_user
  end

  def find_portal_setting(params = {})
    portal = portal_setting.site(params[:cur_site]).first || Gws::Portal::UserSetting.new(
      {
        site_id: params[:cur_site].id,
        portal_user_id: id,
        readable_member_ids: [id],
        user_ids: [id]
      }
    )
    portal.name = long_name
    portal.attributes = params
    portal
  end
end
