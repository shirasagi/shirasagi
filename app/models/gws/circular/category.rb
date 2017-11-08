class Gws::Circular::Category
  include Gws::Model::Category
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_circular_posts'

  default_scope ->{ where(model: 'gws/circular/category').order_by(name: 1) }

end
