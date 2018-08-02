class Gws::Portal::GroupSetting
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Portal::PortalModel
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  index({ portal_group_id: 1, site_id: 1 }, { unique: true })

  field :name, type: String
  belongs_to :portal_group, class_name: 'Gws::Group', inverse_of: :portal_group_setting
  has_many :portlets, class_name: 'Gws::Portal::GroupPortlet', dependent: :destroy

  validates :name, presence: true
  validates :portal_group_id, presence: true, uniqueness: { scope: :site_id }

  def portlet_models
    %w(free links schedule bookmark report workflow circular monitor board faq qna share attendance notice presence survey).map do |key|
      Gws::Portal::GroupPortlet.portlet_model(key)
    end
  end

  def default_portlets
    Gws::Portal::GroupPortlet.default_portlets(SS.config.gws['portal']['group_portlets'])
  end
end
