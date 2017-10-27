class Gws::Portal::GroupSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  #include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  index({ portal_group_id: 1 }, { unique: true })

  field :name, type: String
  belongs_to :portal_group, class_name: 'Gws::Group', inverse_of: :portal_group_setting
  has_many :portlets, class_name: 'Gws::Portal::GroupPortlet', dependent: :destroy

  validates :name, presence: true
  validates :portal_group_id, presence: true, uniqueness: true
  before_validation :set_name, if: ->{ portal_group.present? }

  def portal_type
    :group
  end

  def default_portlets
    %w(schedule reminder board).map { |key| Gws::Portal::GroupPortlet.default_portlet(key) }
  end

  def readable_portlets(user, site)
    return default_portlets unless self.allowed?(:read, user, site: site)
    return default_portlets unless portlets.present?
    portlets
  end

  private

  def set_name
    self.name = portal_group.name
  end
end
