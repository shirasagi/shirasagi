class Gws::Facility::Item
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include SS::Scope::ActivationDate
  include SS::Addon::Markdown
  include Gws::Addon::Facility::ColumnSetting
  include Gws::Addon::Facility::ReservableSetting
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  store_in collection: "gws_facilities"

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :activation_date, type: DateTime
  field :expiration_date, type: DateTime
  field :min_minutes_limit, type: Integer
  field :max_minutes_limit, type: Integer
  field :max_days_limit, type: Integer

  belongs_to :category, class_name: 'Gws::Facility::Category'

  permit_params :name, :order, :category_id, :activation_date, :expiration_date
  permit_params :min_minutes_limit, :max_minutes_limit, :max_days_limit

  validates :name, presence: true
  validates :activation_date, datetime: true
  validates :expiration_date, datetime: true
  validates :min_minutes_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :max_minutes_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  validates :max_days_limit, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }

  default_scope -> { order_by order: 1, name: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:category].present?
      criteria = criteria.where(category_id: params[:category])
    end

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :text
    end
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
