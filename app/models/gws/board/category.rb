class Gws::Board::Category
  include Gws::Model::Category
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  default_scope ->{ where(model: "gws/board/category").order_by(name: 1) }

  class << self
    def categories_for(site, user)
      Gws::Board::Category.site(site).target_to(user)
    end
  end
end
