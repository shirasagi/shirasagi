class Gws::CustomGroup
  include SS::Document
  include SS::Fields::Normalizer
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include Gws::Addon::GroupPermission

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  has_many :users, class_name: "Gws::CustomGroupUser", dependent: :destroy

  permit_params :name, :order

  validates :name, presence: true, length: { maximum: 40 }

  default_scope ->{ order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  def real_users
    users.map(&:user).compact
  end
end
