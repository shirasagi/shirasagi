class Gws::Schedule::Category
  include Gws::Model::Category
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  has_many :plans, class_name: 'Gws::Schedule::Plan'

  default_scope -> {
    where(model: "gws/schedule/category").order_by(name: 1)
  }
end
