class Gws::Share::Category
  include Gws::Model::Category
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  default_scope ->{ where(model: "gws/share/category").order_by(name: 1) }

  class << self
    def categories_for(site, user)
      Gws::Share::Category.site(site).target_to(user)
    end
  end
end
