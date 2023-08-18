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

  def import_convert_data(data)
    # readable_group_ids
    case data[:readable_setting_range]
    when I18n.t("gws.options.readable_setting_range.public")
      readable_setting_range = "public"
    when I18n.t("gws.options.readable_setting_range.select")
      readable_setting_range = "select"
    else # I18n.t("gws.options.readable_setting_range.private")
      readable_setting_range = "private"
    end
    data[:readable_setting_range] = readable_setting_range
    # readable_group_ids
    group_ids = data[:readable_group_ids]
    if group_ids
      data[:readable_group_ids] = Gws::Group.site(@cur_site).active.in(name: group_ids.split(/\R/)).pluck(:id)
    else
      data[:readable_group_ids] = []
    end
    # readable_member_ids
    user_ids = data[:readable_member_ids]
    if user_ids
      data[:readable_member_ids] = Gws::User.site(@cur_site).active.in(uid: user_ids.split(/\R/)).pluck(:id)
    else
      data[:readable_member_ids] = []
    end
    # group_ids
    group_ids = data[:group_ids]
    if group_ids
      data[:group_ids] = Gws::Group.site(@cur_site).active.in(name: group_ids.split(/\R/)).pluck(:id)
    else
      data[:group_ids] = []
    end
    # user_ids
    user_ids = data[:user_ids]
    if user_ids
      data[:user_ids] = Gws::User.site(@cur_site).active.in(uid: user_ids.split(/\R/)).pluck(:id)
    else
      data[:user_ids] = []
    end

    data
  end
end
