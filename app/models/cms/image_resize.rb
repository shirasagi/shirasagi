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

    def effective_resize(user: nil, site: nil, node: nil, request_disable: false)
      # 現在の cms/image_reisze は node が必須。node が未指定の場合は無制限を表す nil を返す
      return nil if node.blank?

      site ||= node.site
      return nil if site.blank?
      return nil if request_disable && user && Cms::ImageResize.allowed?(:disable, user.cms_user, site: site)

      criteria = Cms::ImageResize.site(site)
      criteria = criteria.node(node)
      criteria = criteria.where(state: Cms::ImageResize::STATE_ENABLED)
      all_ids = criteria.pluck(:id)
      return nil if all_ids.blank?

      ret = new
      all_ids.each_slice(20) do |ids|
        criteria.in(id: ids).to_a.each { ret = Cms::ImageResize.intersection(ret, _1) }
      end

      ret
    end
  end
end
