class Gws::Workload::Graph::UserSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workload::Graph
  include Gws::SitePermission

  set_permission_name 'gws_workload_settings', :edit

  seqid :id
  field :name, type: String
  field :order, type: Integer
  belongs_to :group, class_name: "Gws::Group"

  validates :group_id, presence: true
  before_save :set_name

  default_scope -> { order_by(order: 1) }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    if params[:keyword].present?
      criteria = criteria.keyword_in params[:keyword], :name
    end
    criteria
  }

  private

  def set_name
    self.name = user.name
  end

  class << self
    def create_settings(users, cond = {})
      items = users.map.with_index do |user, idx|
        item = self.find_or_initialize_by({ user_id: user.id }.merge(cond))
        item.order = (idx + 1) * 10
        item.save!
        item
      end
      self.criteria.in(id: items.map(&:id))
    end
  end
end
