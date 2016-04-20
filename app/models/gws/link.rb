class Gws::Link
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include SS::Addon::Body
  include Gws::Addon::Release
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String

  permit_params :name

  validates :name, presence: true, length: { maximum: 80 }

  default_scope -> {
    order_by released: -1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :html if params[:keyword].present?
    criteria
  }
end
