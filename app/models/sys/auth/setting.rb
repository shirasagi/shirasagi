class Sys::Auth::Setting
  include SS::Document
  include Sys::Permission
  include SS::Ldap::SiteSetting
  include SS::MFA::SiteSetting

  DEFAULT_KEY = "user".freeze
  DEFAULT_PASSWORD = "guest".freeze

  set_permission_name "sys_users", :edit

  field :form_auth, type: String, default: "enabled"
  field :form_key, type: String
  field :form_password, type: String
  field :form_enabled_ip_addresses, type: SS::Extensions::Lines

  attr_accessor :in_form_password

  permit_params :form_auth, :form_key, :in_form_password, :form_enabled_ip_addresses

  before_validation :update_form_password
  validates :form_enabled_ip_addresses, ip_address: true

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

  def form_enabled_ip_addresses_any?(request = nil)
    return false if form_enabled_ip_addresses.blank?

    remote_addr = SS.remote_addr(request)
    enabled = form_enabled_ip_addresses.any? do |addr|
      next false if addr.blank? || addr.start_with?("#")

      addr = IPAddr.new(addr) rescue nil
      next false unless addr

      addr.include?(remote_addr)
    end
    enabled
  end

  def form_auth_available?(param, request = nil)
    return true if form_auth_enabled?
    return true if form_enabled_ip_addresses_any?(request)

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
