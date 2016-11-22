class Cms::MaxFileSize
  include SS::Model::MaxFileSize
  include SS::Reference::Site
  include Cms::Reference::Node

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

    def allow(action, user, opts = {})
       opts_node = opts[:node]
       return where({}) unless opts_node

       if opts_node.allowed?(action, user, opts)
         where({})
       else
         none
       end
    end

    def allowed?(action, user, opts = {})
      opts_node = opts[:node]
      return true unless opts_node

      opts_node.allowed?(action, user, opts)
    end
  end

  def allowed?(action, user, opts = {})
    return true unless node

    node.allowed?(action, user, opts)
  end
end
