class Gws::Portal::UserSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortalModel
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  index({ portal_user_id: 1, site_id: 1 }, { unique: true })

  no_needs_read_permission_to_read

  field :name, type: String
  belongs_to :portal_user, class_name: 'Gws::User', inverse_of: :portal_user_setting
  has_many :portlets, class_name: 'Gws::Portal::UserPortlet', dependent: :destroy

  validates :name, presence: true
  validates :portal_user_id, presence: true, uniqueness: { scope: :site_id }

  def portlet_models
    %w(free links reminder schedule todo bookmark report workflow circular monitor board faq qna share
       attendance notice presence survey ad).map do |key|
      Gws::Portal::UserPortlet.portlet_model(key)
    end
  end

  def default_portlets(settings = [])
    Gws::Portal::UserPortlet.default_portlets(settings.presence || SS.config.gws['portal']['user_portlets'])
  end
end
