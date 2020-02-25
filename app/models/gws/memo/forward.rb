class Gws::Memo::Forward
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  MAX_MAIL_COUNT = SS.config.gws.dig("memo", "max_foward_mail_address_count") || 10

  set_permission_name 'private_gws_memo_messages', :edit

  field :default, type: String, default: 'disabled'
  field :emails, type: SS::Extensions::Words

  permit_params :emails, :default

  validates :emails, presence: true, if: ->{ self.default == "enabled" }
  validates :emails, emails: true, length: { maximum: MAX_MAIL_COUNT, message: :too_large }

  #scope :default, -> { where default: 'disabled' }
  #scope :search, ->(params) {
  #  criteria = where({})
  #  return criteria if params.blank?
  #
  #  criteria = criteria.keyword_in params[:keyword], :name, :text if params[:keyword].present?
  #  criteria
  #}

  def default_options
    %w(enabled disabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  #def default?
  #  default == 'disabled'
  #end
end
