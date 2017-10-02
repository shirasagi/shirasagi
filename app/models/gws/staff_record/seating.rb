class Gws::StaffRecord::Seating
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
  field :url, type: String
  field :remark, type: String

  permit_params :name, :order, :url, :remark

  validates :name, presence: true
  validates :url, presence: true

  default_scope -> { order_by order: 1 }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name, :url, :remark
    end
    criteria
  }

  private

  def export_fields
    %w(id name order url remark)
  end

  def import_find_item(data)
    self.class.site(@cur_site).
      where(year_id: year_id, id: data[:id]).
      allow(:read, @cur_user, site: @cur_site).
      first
  end

  def import_new_item(data)
    self.class.new(data.merge(year_id: year_id))
  end
end
