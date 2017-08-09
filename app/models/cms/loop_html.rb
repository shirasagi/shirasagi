class Cms::LoopHtml
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission
  include Cms::Addon::Html

  set_permission_name "cms_loop_htmls", :edit

  seqid :id
  field :name, type: String
  field :description, type: String
  field :order, type: Integer
  permit_params :name, :description, :order
  validates :name, presence: true, length: { maximum: 40 }
  validates :description, length: { maximum: 400 }

  default_scope -> { order_by(order: 1, name: 1) }

  class << self
    def search(params = {})
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :html
      end
      criteria
    end
  end
end
