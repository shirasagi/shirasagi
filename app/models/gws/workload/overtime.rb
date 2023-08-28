class Gws::Workload::Overtime
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Workload::Yearly
  include Gws::Addon::Workload::Overtime
  include Gws::SitePermission
  include Gws::Addon::History

  set_permission_name 'gws_workload_overtimes'

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
    self.name = "[#{year}#{I18n.t("ss.fiscal_year")}] #{user.name}"
  end

  class << self
    def allowed_manage?(user, opts = {})
      self.allowed?(:manage, user, opts) || self.allowed?(:all, user, opts)
    end

    def allowed_all?(user, opts = {})
      self.allowed?(:all, user, opts)
    end

    def create_settings(year, users, cond = {})
      items = users.map.with_index do |user, idx|
        item = self.find_or_initialize_by({ year: year, user_id: user.id }.merge(cond))
        item.order = (idx + 1) * 10
        item.save!
        item
      end
      self.criteria.in(id: items.map(&:id))
    end
  end
end
