class Gws::Portal::UserSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  #include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  field :name, type: String
  belongs_to :portal_user, class_name: 'Gws::User', inverse_of: :portal_user_setting
  has_many :portlets, class_name: 'Gws::Portal::UserPortlet', dependent: :destroy

  validates :name, presence: true
  validates :portal_user_id, presence: true, uniqueness: true
  before_validation :set_name, if: ->{ portal_user.present? }

  def portal_type
    :user
  end

  def default_portlets
    %w(schedule reminder board).map { |key| Gws::Portal::UserPortlet.default_portlet(key) }
  end

  def readable_portlets(user, site)
    return default_portlets unless self.allowed?(:read, user, site: site)
    return default_portlets unless portlets.present?
    portlets
  end

  private

  def set_name
    self.name = portal_user.long_name
  end
end
