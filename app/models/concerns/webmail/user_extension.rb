module Webmail::UserExtension
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :imap_default_index, type: Integer, default: 0
    field :imap_settings, type: Webmail::Extensions::ImapSettings, default: []
    permit_params :default_imap_index
    permit_params imap_settings: [
      :name, :from, :address, :imap_alias, :imap_host, :imap_port, :imap_ssl_use,
      :imap_auth_type, :imap_account, :in_imap_password,
      :imap_sent_box, :imap_draft_box, :imap_trash_box, :threshold_mb,
      :default
    ]

    validate :validate_imap_settings
  end

  def imap_auth_type_options
    %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5).map { |c| [c, c] }
  end

  def imap_ssl_use_options
    %w(disabled enabled).map { |c| [I18n.t("webmail.options.imap_ssl_use.#{c}"), c] }
  end

  def imap_default_settings
    @imap_default_settings ||= begin
      yaml = SS.config.webmail.clients['default'] || {}
      {
        address: email,
        host: yaml['host'].presence,
        options: (yaml['options'].presence || {}).symbolize_keys,
        auth_type: yaml['auth_type'].presence,
        account: send(yaml['account'].presence).to_s,
        password: decrypted_password
      }
    end
  end

  def initialize_imap(account_index)
    setting = imap_settings[account_index]
    setting = Webmail::ImapSetting.default if setting.nil? && account_index == 0
    return if setting.nil?

    Webmail::Imap::Base.new_by_user(self, setting)
  end

  private

  def validate_imap_settings
    self.imap_settings = self.imap_settings.map.with_index do |setting, i|
      if setting[:default]
        self.imap_default_index = i
        setting.delete(:default)
      end
      setting[:imap_port] = (setting.imap_port.to_i > 0) ? setting.imap_port.to_i : nil
      setting[:threshold_mb] = (setting.threshold_mb.to_i > 0) ? setting.threshold_mb.to_i : nil
      setting.set_imap_password
      setting
    end
    self.imap_default_index = 0 if imap_settings[imap_default_index].nil?
    self.imap_settings.each_with_index do |setting, i|
      setting.valid?
      if setting.errors.present?
        SS::Model.copy_errors(setting, self, prefix: "#{I18n.t("webmail.account_setting")}#{i + 1}: ")
      end
    end
  end
end
