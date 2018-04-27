class Gws::Memo::Forward
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'private_gws_memo_messages', :edit

  field :default, type: String, default: 'disabled'
  field :email, type: String

  permit_params :email, :default

  validates :email, presence: true, if: ->{ self.default == "enabled" }
  validates :email, email: true, if: ->{ email.present? }

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
end
