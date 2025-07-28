class Gws::Role
  include SS::Model::Role
  include Gws::Referenceable
  include Gws::Reference::Site
  include Gws::SitePermission
  include Gws::Addon::History
  include Gws::Addon::Import::Role

  set_permission_name "gws_roles", :edit
end
