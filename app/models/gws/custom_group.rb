class Gws::CustomGroup
  include SS::Document
  include SS::Fields::Normalizer
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include Gws::Addon::GroupPermission

  permission_include_user

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  embeds_ids :members, class_name: "Gws::User"

  permit_params :name, :order, member_ids: []

  validates :name, presence: true, length: { maximum: 40 }
  validates :member_ids, presence: true

  default_scope ->{ order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }
end
