class Gws::CustomGroup
  include SS::Document
  include SS::Fields::Normalizer
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  # Member addon setting
  keep_members_order

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 40 }

  default_scope ->{ order_by order: 1 }

  scope :member, ->(user) { where member_ids: user.id }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }
end
