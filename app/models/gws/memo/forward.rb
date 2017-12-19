class Gws::Memo::Forward
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'gws_memo_messages'

  field :default, type: String, default: 'disabled'
  field :email, type: String

  permit_params :email, :default

  validates :email, email: true, if: ->{ email.present? }
  validate :check_forward, if: ->{ self.default == "enabled" }

  after_save :check_default, if: ->{ default? }

  #default_scope -> { order_by name: 1 }

  scope :default, -> { where default: 'disabled' }
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
    default == 'disabled'
  end

  private

  def check_default
    self.class.user(user).
        where(default: 'disabled').
        where(:id.ne => id).
        update_all(default: 'disabled')
  end

  def check_forward
    if self.email.blank?
      errors.add :base, :not_set_email
      return false
    end
    true
  end

end
