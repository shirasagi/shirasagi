class Gws::StaffRecord::Group
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Export

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :seating_chart_url, type: String

  permit_params :name, :order, :seating_chart_url

  validates :name, presence: true, uniqueness: { scope: [:site_id, :year] }

  default_scope -> { order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :seating_chart_url
    end
    criteria
  }

  private

  def export_fields
    %w(id name order seating_chart_url)
  end
end
