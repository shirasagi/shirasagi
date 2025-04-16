class Cms::Transaction::Plan
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::SitePermission

  set_permission_name "cms_transactions", :use

  seqid :id
  field :name, type: String
  field :order, type: Integer
  field :start_at, type: DateTime
  has_many :units, class_name: 'Cms::Transaction::Unit::Base', dependent: :destroy, inverse_of: :plan

  permit_params :name, :order, :start_at
  validates :name, presence: true, length: { maximum: 40 }
  validates :start_at, presence: true

  default_scope -> { order_by(order: 1, name: 1) }

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

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
