class Chat::Category
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  index({ updated: -1 })

  set_permission_name "chat_bots", :edit

  field :name, type: String

  permit_params :name

  validates :name, presence: true

  class << self
    def search(params)
      criteria = all
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
