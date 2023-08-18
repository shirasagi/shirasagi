class Cms::ImageResize
  include SS::Model::ImageResize
  include SS::Reference::Site
  include Cms::Reference::Node
  include Cms::SitePermission

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
