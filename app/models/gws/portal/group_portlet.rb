class Gws::Portal::GroupPortlet
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortletModel
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  set_permission_name "gws_portal_group_settings"
  no_needs_read_permission_to_read

  belongs_to :setting, class_name: 'Gws::Portal::GroupSetting'
end
