class Gws::Affair::SpecialLeave
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission
  include Gws::SitePermission
  include Gws::Addon::Import::Affair::SpecialLeave

  set_permission_name "gws_affair_special_leaves"

  seqid :id
  field :code, type: String
  field :name, type: String
  field :order, type: Integer, default: 0
  field :staff_category, type: String

  permit_params :code, :name, :order, :staff_category

  validates :name, presence: true, length: { maximum: 80 }
  validates :staff_category, presence: true

  class << self
    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :no, :name, :remark
      end
      if params[:staff_category].present?
        criteria = criteria.where(staff_category: params[:staff_category])
      end
      criteria
    end
  end
end
