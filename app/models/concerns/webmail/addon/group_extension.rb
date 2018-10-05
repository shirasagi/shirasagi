module Webmail::Addon::GroupExtension
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    attr_accessor :default_imap_setting
    field :imap_settings, type: Webmail::Extensions::ImapSettings, default: []
    permit_params imap_settings: %i(
      name from address imap_host imap_port imap_ssl_use
      imap_auth_type imap_account in_imap_password
      imap_sent_box imap_draft_box imap_trash_box
      threshold_mb
    )

    validate :validate_imap_settings
  end

  def imap_setting
    @imap_setting ||= imap_settings[0] || Webmail::ImapSetting.new
  end

  def imap_auth_type_options
    %w(LOGIN PLAIN CRAM-MD5 DIGEST-MD5)
  end

  def imap_ssl_use_options
    %w(disabled enabled).map { |c| [I18n.t("webmail.options.imap_ssl_use.#{c}"), c] }
  end

  def default_imap_setting_changed?
    new_imap_setting = Webmail::ImapSetting.new

    default_imap_setting = imap_setting.keys.each_with_object({}) do |key, h|
      h[key] = new_imap_setting[key] || new_imap_setting.imap_settings[key] || ''
    end

    default_imap_setting != imap_setting
  end

  private

  def validate_imap_settings
    return self.imap_settings = [] if !default_imap_setting_changed?
    imap_setting[:imap_port] = (imap_setting.imap_port.to_i > 0) ? imap_setting.imap_port.to_i : nil
    imap_setting[:threshold_mb] = (imap_setting.threshold_mb.to_i > 0) ? imap_setting.threshold_mb.to_i : nil
    imap_setting.set_imap_password
    self.imap_settings = [imap_setting]
    return if imap_setting.valid?
    errors.add :base, imap_setting.errors.full_messages.join(", ")
  end
end
