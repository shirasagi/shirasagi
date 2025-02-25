class Gws::StaffRecord::UserTitle
  include SS::Model::UserTitle
  include Gws::Referenceable
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly
  include Gws::Export

  store_in collection: "gws_staff_record_user_titles"

  attr_accessor :cur_user, :cur_site

  validates :code, uniqueness: { scope: [:group_id, :year] }
  before_validation :set_group_id, if: -> { cur_site.present? }
  after_save :update_users_title_order

  default_scope -> { order_by(order: -1) }

  class << self
    # override scope
    def site(site)
      where group_id: site.id
    end
  end

  private

  def set_group_id
    self.group_id = cur_site.id
  end

  def update_users_title_order
    return if self.order_was.nil?
    Gws::StaffRecord::User.update_all_title_orders(self)
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

  def export_fields
    %w(
      id code name remark order
      group_ids user_ids
    )
  end

  def export_convert_item(item, data)
    # group_ids
    data[5] = Gws::Group.site(@cur_site).in(id: data[5]).active.pluck(:name).join("\n")
    # user_ids
    data[6] = Gws::User.site(@cur_site).in(id: data[6]).active.pluck(:uid).join("\n")

    data
  end
end
