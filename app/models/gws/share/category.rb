class Gws::Share::Category
  include Gws::Model::Category
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  default_scope ->{ where(model: "gws/share/category").order_by(name: 1) }

  scope :search, ->(params) do
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  end
end
