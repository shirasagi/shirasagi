class Gws::Share::File
  include SS::Model::File
  include Gws::Reference::Site
  include Gws::Addon::Share::Category
  include Gws::Addon::GroupPermission

  validates :category_ids, presence: true

  default_scope ->{ where(model: "share/file") }

  class << self
    def search(params)
      criteria = super
      return criteria if params.blank?

      if params[:category].present?
        category_ids = Gws::Share::Category.site(params[:site]).and_name_prefix(params[:category]).pluck(:id)
        criteria = criteria.in(category_ids: category_ids)
      end

      criteria
    end
  end

  def remove_public_file
    #TODO: fix SS::Model::File
  end
end
