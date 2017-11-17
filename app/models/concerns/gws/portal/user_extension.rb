module Gws::Portal::UserExtension
  extend ActiveSupport::Concern

  included do
    has_one :portal_setting, class_name: 'Gws::Portal::UserSetting',
      foreign_key: :portal_user_id, dependent: :destroy, inverse_of: :portal_user
  end

  def find_portal_setting(params = {})
    portal_setting || Gws::Portal::UserSetting.new({
      portal_user_id: id,
      readable_member_ids: [id],
      user_ids: [id]
    }.merge(params))
  end
end
