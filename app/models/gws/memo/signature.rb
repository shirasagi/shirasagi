class Gws::Memo::Signature
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Gws::SitePermission

  set_permission_name 'private_gws_memo_messages', :edit

  field :name, type: String
  field :text, type: String
  field :default, type: String, default: 'disabled'

  permit_params :name, :text, :default

  validates :name, presence: true
  validates :text, presence: true

  after_save :check_default, if: ->{ default? }

  default_scope -> { order_by name: 1 }

  scope :default, -> { where default: 'enabled' }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
    criteria
  }

  def default_options
    %w(enabled disabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def default?
    default == 'enabled'
  end

  private

  def check_default
    self.class.site(@cur_site || site).user(user).
      where(default: 'enabled').
      where(:id.ne => id).
      update_all(default: 'disabled')
  end

  class << self
    def default_sign(user)
      sign = self.user(user).default.first
      sign ? sign.text.presence : nil
    end
  end
end
