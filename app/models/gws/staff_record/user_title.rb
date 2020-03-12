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
  scope :site, ->(site) { where group_id: site.id }

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

  def export_fields
    %w(
      id created updated deleted text_index code name remark order group_id
      permission_level group_ids user_ids custom_group_ids user_uid user_name user_group_id user_group_name user_id
      site_id year_code year_name year_id
    )
  end
end
