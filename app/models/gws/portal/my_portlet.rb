class Gws::Portal::MyPortlet
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortletModel
  include SS::FreePermission
  include Gws::Addon::History

  belongs_to :setting, class_name: 'Gws::Portal::MySetting'
end
