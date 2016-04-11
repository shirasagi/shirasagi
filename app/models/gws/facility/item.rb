class Gws::Facility::Item
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Addon::Markdown
  include Gws::Addon::GroupPermission

  store_in collection: "gws_facilities"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0

  belongs_to :category, class_name: 'Gws::Facility::Category'

  permit_params :name, :order, :category_id

  validates :name, presence: true

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }
  scope :category_id, ->(category_id) { where category_id: category_id.presence }

  def category_options
    @category_options ||= Gws::Facility::Category.site(@cur_site || site).
      map { |c| [c.name, c.id] }
  end
end
