class Cms::PageSearch
  include SS::Document
  include SS::Reference::Site
  include Cms::Addon::PageSearch
  include Cms::Addon::GroupPermission

  attr_accessor :cur_user

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :search_name, :search_filename
      end
      criteria
    end
  end
end
