class Gws::Schedule::Category
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Content::Targetable
  include Gws::Schedule::Colorize
  include Gws::Addon::GroupPermission

  field :state, type: String, default: "public"
  field :name, type: String
  field :color, type: String, default: "#4488bb"

  has_many :plans, class_name: 'Gws::Schedule::Plan'

  permit_params :state, :name, :color

  validates :state, presence: true
  validates :name, presence: true
  validates :color, presence: true

  default_scope -> {
    order_by name: 1
  }
  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }
end
