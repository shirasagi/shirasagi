module Gws::Portal::UserExtension
  extend ActiveSupport::Concern

  included do
    has_one :portal_my_setting, class_name: 'Gws::Portal::MySetting',
      foreign_key: :portal_user_id, dependent: :destroy, inverse_of: :portal_user

    has_one :portal_user_setting, class_name: 'Gws::Portal::UserSetting',
      foreign_key: :portal_user_id, dependent: :destroy, inverse_of: :portal_user
  end

  def find_or_new_portal_my_setting(params = {})
    portal_my_setting || Gws::Portal::MySetting.new({
      portal_user_id: id,
      user_ids: [id]
    }.merge(params))
  end

  def find_or_new_portal_user_setting(params = {})
    portal_user_setting || Gws::Portal::UserSetting.new({
      portal_user_id: id,
      user_ids: [id]
    }.merge(params))
  end
end
