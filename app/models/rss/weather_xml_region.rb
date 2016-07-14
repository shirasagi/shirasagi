class Rss::WeatherXmlRegion
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  seqid :id
  field :name, type: String
  field :code, type: String
  field :order, type: Integer, default: 0
  validates :name, presence: true, length: { maximum: 40 }
  validates :code, presence: true, length: { maximum: 40 }
  permit_params :name, :code, :order

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :code
      end
      criteria
    end
  end
end
