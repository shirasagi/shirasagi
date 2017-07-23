class Gws::StaffRecord::Year
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  #field :order, type: Integer, default: 0
  field :year, type: Integer
  field :start_date, type: Date
  field :close_date, type: Date

  permit_params :name, :year, :start_date, :close_date

  validates :name, presence: true, uniqueness: { scope: :site_id }
  validates :year, presence: true, numericality: { greater_than: 0, less_than: 10_000 }
  validates :start_date, datetime: true
  validates :close_date, datetime: true

  default_scope -> { order_by start_date: -1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?
    criteria = criteria.keyword_in params[:keyword], :name, :year if params[:keyword].present?
    criteria
  }

  def name_with_year
    "#{name} / #{year}"
  end
end
