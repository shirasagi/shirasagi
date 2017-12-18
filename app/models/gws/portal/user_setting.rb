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

  field :name, type: String
  belongs_to :portal_user, class_name: 'Gws::User', inverse_of: :portal_user_setting
  has_many :portlets, class_name: 'Gws::Portal::UserPortlet', dependent: :destroy

  validates :name, presence: true
  validates :portal_user_id, presence: true, uniqueness: { scope: :site_id }

  before_validation :set_name, if: ->{ portal_user.present? }

  def portlet_models
    %w(free links schedule reminder bookmark board faq qna circular monitor share report workflow).map do |key|
      Gws::Portal::UserPortlet.portlet_model(key)
    end
  end

  def default_portlets
    %w(schedule reminder monitor circular board faq qna).map do |key|
      Gws::Portal::UserPortlet.default_portlet(key)
    end
  end

  private

  def set_name
    self.name = portal_user.long_name if self.name.blank?
  end
end
