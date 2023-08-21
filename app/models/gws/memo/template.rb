class Gws::Memo::Template
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  set_permission_name 'gws_memo_templates'

  field :name, type: String
  field :text, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :text, :order

  validates :name, presence: true
  validates :text, presence: true

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }
end
