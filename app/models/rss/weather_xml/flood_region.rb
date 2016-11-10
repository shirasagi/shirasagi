class Rss::WeatherXml::FloodRegion
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  set_permission_name "cms_tools", :use

  seqid :id
  field :code, type: String
  field :name, type: String
  field :yomi, type: String
  field :order, type: Integer, default: 0
  field :state, type: String, default: 'enabled'
  validates :code, presence: true, length: { maximum: 40 }
  validates :name, presence: true, length: { maximum: 40 }
  validates :yomi, length: { maximum: 40 }
  validates :state, inclusion: { in: %w(enabled disabled), allow_blank: true }
  permit_params :name, :yomi, :code, :order

  scope :and_enabled, -> { self.in(state: [nil, 'enabled'])}

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :code, :name, :yomi
      end
      criteria
    end
  end
end
