class Gws::Facility::Item
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Scope::ActivationDate
  include SS::Addon::Markdown
  include Gws::Addon::ReadableSetting
  include Gws::Addon::Facility::ReservableSetting
  include Gws::Addon::GroupPermission

  store_in collection: "gws_facilities"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :activation_date, type: DateTime
  field :expiration_date, type: DateTime

  belongs_to :category, class_name: 'Gws::Facility::Category'

  permit_params :name, :order, :category_id, :activation_date, :expiration_date

  validates :name, presence: true
  validates :activation_date, datetime: true
  validates :expiration_date, datetime: true

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }
  scope :category_id, ->(category_id) do
    if category_id.present?
      where category_id: category_id.id
    else
      where({})
    end
  end

  def category_options
    @category_options ||= Gws::Facility::Category.site(@cur_site || site).
      map { |c| [c.name, c.id] }
  end
end
