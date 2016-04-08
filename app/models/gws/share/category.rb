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

    def grouped_categories_for(site, user)
      root_hash = {}
      categories_for(site, user).map do |category|
        parts = category.name.split('/')
        hash = root_hash
        parts.each do |n|
          hash[n] ||= {}
          hash = hash[n]
        end
      end
      root_hash
    end

    def and_name_prefix(name_prefix)
      name_prefix = name_prefix[1..-1] if name_prefix.starts_with?('/')
      self.or({ name: name_prefix }, { name: /^Regexp.escape(name_prefix)\// })
    end
  end

  private
    def color_required?
      false
    end
end
