class Gws::Schedule::Category
  include Gws::Model::Category
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  has_many :plans, class_name: 'Gws::Schedule::Plan'

  default_scope -> {
    where(model: "gws/schedule/category").order_by(name: 1)
  }

  class << self
    def to_options
      self.all.map { |c| [c.name, c.id] }
    end
  end
end
