class Gws::Portal::UserPortlet
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortletModel
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  set_permission_name "gws_portal_user_settings"

  belongs_to :setting, class_name: 'Gws::Portal::UserSetting'
end
