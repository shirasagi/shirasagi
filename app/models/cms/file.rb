class Cms::File
  include SS::Model::File
  include SS::Reference::Site
  include Cms::Addon::GroupPermission

  default_scope ->{ where(model: "cms/file") }

  class << self
    public
      def search(params)
        criteria = self.where({})
        return criteria if params.blank?

        if params[:name].present?
          criteria = criteria.search_text params[:name]
        end
        if params[:keyword].present?
          criteria = criteria.keyword_in params[:keyword], :filename
        end
        criteria
      end
  end
end
