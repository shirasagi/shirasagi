class Gws::StaffRecord::Group
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  seqid :id
  field :name, type: String
  field :code, type: String
  field :seating_chart_url, type: String

  belongs_to :category, class_name: 'Gws::Facility::Category'

  permit_params :name, :code, :seating_chart_url

  validates :name, presence: true, uniqueness: { scope: [:site_id, :year] }
  validates :code, presence: true, uniqueness: { scope: [:site_id, :year] }

  default_scope -> { order_by year: -1, code: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :code, :year, :year_name, :seating_chart_url
    end
    criteria = criteria.where(year: params[:year]) if params[:year].present?
    criteria
  }
end
