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
    fields = %w(
      id name url remark order
      readable_setting_range readable_group_ids readable_member_ids
      group_ids user_ids
    )
    unless SS.config.ss.disable_permission_level
      fields << "permission_level"
    end

    fields
  end

  def export_convert_item(item, data)
    # readable_setting_range
    data[5] = item.label(:readable_setting_range)
    # readable_group_ids
    data[6] = Gws::Group.site(@cur_site).in(id: data[6]).active.pluck(:name).join("\n")
    # readable_member_ids
    data[7] = Gws::User.site(@cur_site).in(id: data[7]).active.pluck(:uid).join("\n")
    # group_ids
    data[8] = Gws::Group.site(@cur_site).in(id: data[8]).active.pluck(:name).join("\n")
    # user_ids
    data[9] = Gws::User.site(@cur_site).in(id: data[9]).active.pluck(:uid).join("\n")

    data
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
