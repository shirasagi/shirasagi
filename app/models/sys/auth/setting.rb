class Sys::Auth::Setting
  include SS::Document
  include Sys::Permission
  include SS::Ldap::SiteSetting

  DEFAULT_KEY = "user".freeze
  DEFAULT_PASSWORD = "guest".freeze

  set_permission_name "sys_users", :edit

  field :form_auth, type: String, default: "enabled"
  field :form_key, type: String
  field :form_password, type: String

  attr_accessor :in_form_password

  permit_params :form_auth, :form_key, :in_form_password

  before_validation :update_form_password

  class << self
    class Current < ActiveSupport::CurrentAttributes
      attribute :item
    end

    def instance
      Current.item ||= Sys::Auth::Setting.first_or_create
    end
  end

  def form_auth_options
    [
      [I18n.t('ss.options.state.enabled'), "enabled"],
      [I18n.t('ss.options.state.disabled'), "disabled"]
    ]
  end

  def form_auth_disabled?
    form_auth == "disabled"
  end

  def form_auth_enabled?
    !form_auth_disabled?
  end

  def form_auth_available?(param)
    return true if form_auth_enabled?

    password = param[form_key.presence || DEFAULT_KEY]
    return false if password.blank?

    if form_password.present?
      password == SS::Crypto.decrypt(form_password)
    else
      password == DEFAULT_PASSWORD
    end
  end

  private

  def update_form_password
    return if in_form_password.blank?
    self.form_password = SS::Crypto.encrypt(in_form_password)
  end
end
