class Gws::StaffRecord::UserTitle
  include SS::Model::UserTitle
  include Gws::Referenceable
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::StaffRecord::Yearly

  store_in collection: "gws_staff_record_user_titles"

  attr_accessor :cur_user, :cur_site

  before_validation :set_group_id, if: -> { cur_site.present? }
  after_save :update_users_title_order

  default_scope -> { order_by(order: -1) }
  scope :site, ->(site) { where group_id: site.id }

  def users
    Gws::User.in(title_ids: self.id)
  end

  private

  def set_group_id
    self.group_id = cur_site.id
  end

  def update_users_title_order
    return if self.order_was.nil?
    Gws::User.update_all_title_orders(self)
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
