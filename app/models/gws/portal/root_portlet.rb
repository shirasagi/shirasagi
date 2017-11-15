class Gws::Portal::RootPortlet
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortletModel
  include SS::FreePermission
  include Gws::Addon::History

  store_in collection: :gws_portal_group_portlets

  belongs_to :setting, class_name: 'Gws::Portal::RootSetting'
end
