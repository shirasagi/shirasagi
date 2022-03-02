class Gws::UserOccupation
  include SS::Model::UserOccupation
  include Gws::Referenceable
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name "gws_user_occupations", :edit

  attr_accessor :cur_user, :cur_site

  validates :code, uniqueness: { scope: :group_id }
  before_validation :set_group_id, if: -> { cur_site.present? }
  after_save :update_users_occupation_order

  default_scope -> { order_by(order: -1) }
  scope :site, ->(site) { where group_id: site.id }

  class << self
    def enum_csv(options)
      drawer = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :code
        drawer.column :name
        drawer.column :remark
        drawer.column :order
        # drawer.column :activation_date
        # drawer.column :expiration_date
      end

      drawer.enum(self.all, options)
    end
  end

  def users
    Gws::User.in(occupation_ids: self.id)
  end

  private

  def set_group_id
    self.group_id = cur_site.id
  end

  def update_users_occupation_order
    return if self.order_was.nil?
    Gws::User.update_all_occupation_orders(self)
  end
end
