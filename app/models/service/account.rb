class Service::Account
  include SS::Document
  include SS::Fields::Normalizer
  include SS::FreePermission
  include Service::Addon::Quota

  attr_accessor :add_role, :in_password,
                :in_cms_quota_mb, :in_gws_quota_mb, :in_webmail_quota_mb

  index({ account: 1 }, { unique: true })
  index({ organization_ids: 1 }, { unique: true, sparse: true })

  field :account, type: String
  field :password, type: String
  field :name, type: String
  field :roles, type: SS::Extensions::Words
  field :last_loggedin, type: DateTime
  field :account_start_date, type: DateTime
  field :account_expiration_date, type: DateTime
  field :remark, type: String
  field :cms_use, type: String, default: 'enabled'
  field :gws_use, type: String, default: 'enabled'
  field :webmail_use, type: String, default: 'enabled'
  field :cms_quota, type: Integer, default: nil
  field :gws_quota, type: Integer, default: nil
  field :webmail_quota, type: Integer, default: nil
  field :base_quota_used, type: Integer, default: nil
  field :cms_quota_used, type: Integer, default: nil
  field :gws_quota_used, type: Integer, default: nil
  field :webmail_quota_used, type: Integer, default: nil

  embeds_ids :organizations, class_name: 'SS::Group'

  permit_params :in_password, :account, :password, :name, :roles,
                :account_start_date, :account_expiration_date, :remark,
                :cms_use, :gws_use, :webmail_use, :cms_quota, :gws_quota, :webmail_quota,
                :in_cms_quota_mb, :in_gws_quota_mb, :in_webmail_quota_mb,
                organization_ids: []

  validates :name, presence: true, length: { maximum: 40 }
  validates :account, presence: true, uniqueness: true, length: { maximum: 40 }
  validates :password, presence: true, length: { maximum: 40 }
  validates :account_start_date, datetime: true
  validates :account_expiration_date, datetime: true
  validates :organization_ids, uniqueness: true, allow_nil: true, allow_blank: true

  before_validation :encrypt_password, if: ->{ in_password.present? }
  before_validation :set_add_role, if: ->{ add_role.present? }
  before_validation :set_cms_quota, if: ->{ in_cms_quota_mb }
  before_validation :set_gws_quota, if: ->{ in_gws_quota_mb }
  before_validation :set_webmail_quota, if: ->{ in_webmail_quota_mb }

  default_scope { order_by(account: 1) }

  scope :and_enabled, ->(now = Time.zone.now) do
    self.and(
      { "$or" => [ { "account_start_date" => nil }, { "account_start_date" => { "$lte" => now } } ] },
      { "$or" => [ { "account_expiration_date" => nil }, { "account_expiration_date" => { "$gt" => now } } ] })
  end

  def enabled?
    now = Time.zone.now
    return false if account_start_date.present? && account_start_date > now
    return false if account_expiration_date.present? && account_expiration_date <= now
    true
  end

  def disabled?
    !enabled?
  end

  def admin?
    roles.include?('administrator')
  end

  def cms_enabled?
    cms_use == 'enabled' && !cms_quota_over?
  end

  def gws_enabled?
    gws_use == 'enabled' && !gws_quota_over?
  end

  def webmail_enabled?
    webmail_use == 'enabled' && !webmail_quota_over?
  end

  def cms_quota_over?
    cms_quota.present? && cms_quota_used.present? && cms_quota < cms_quota_used
  end

  def gws_quota_over?
    gws_quota.present? && gws_quota_used.present? && gws_quota < gws_quota_used
  end

  def webmail_quota_over?
    webmail_quota.present? && webmail_quota_used.present? && webmail_quota < webmail_quota_used
  end

  def cms_use_options
    %w(enabled disabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
  end

  def gws_use_options
    %w(enabled disabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
  end

  def webmail_use_options
    %w(enabled disabled).map { |m| [ I18n.t("ss.options.state.#{m}"), m ] }
  end

  def set_quota_mb
    self.in_cms_quota_mb = cms_quota / (1_024 * 1_024) if cms_quota
    self.in_gws_quota_mb = gws_quota / (1_024 * 1_024) if gws_quota
    self.in_webmail_quota_mb = webmail_quota / (1_024 * 1_024) if webmail_quota
  end

  def sites
    return @sites if @sites
    org_ids = organizations.map { |m| m.root.id }.uniq
    SS::Site.any_in(group_ids: org_ids)
  end

  private

  def encrypt_password
    self.password = SS::Crypt.crypt(in_password)
  end

  def set_add_role
    roles = self.roles
    return if roles.include?(add_role)
    roles << add_role
    self.roles = roles
  end

  def set_cms_quota
    self.cms_quota = in_cms_quota_mb.present? ? (in_cms_quota_mb.to_i * 1_024 * 1_024) : nil
  end

  def set_gws_quota
    self.gws_quota = in_gws_quota_mb.present? ? (in_gws_quota_mb.to_i * 1_024 * 1_024) : nil
  end

  def set_webmail_quota
    self.webmail_quota = in_webmail_quota_mb.present? ? (in_webmail_quota_mb.to_i * 1_024 * 1_024) : nil
  end

  class << self
    def authenticate(account, password)
      return nil if account.blank? || password.blank?
      item = where(account: account).first
      return nil unless item
      return SS::Crypt.crypt(password) == item.password ? item : nil
    end
  end
end
