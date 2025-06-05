class Webmail::GroupExport::Base
  include ActiveModel::Model
  extend SS::Translation
  include SS::PermitParams

  def self.with_imap_prefix(label)
    if label.start_with?("IMAP/")
      label.sub("/", "_")
    else
      "IMAP_#{label}"
    end
  end

  BASE_ATTRIBUTES = [
    { key: 'id', label: Webmail::Group.t('id'), setter: :none },
    { key: 'name', label: Webmail::Group.t('name') }
  ].freeze
  IMAP_SETTING_ATTRIBUTES = [
    { key: 'imap_setting.account_index', label: with_imap_prefix(Webmail::Group.t('account_index')), setter: :none },
    { key: 'imap_setting.name', label: with_imap_prefix(Webmail::ImapSetting.t('name')) },
    { key: 'imap_setting.from', label: with_imap_prefix(Webmail::ImapSetting.t('from')) },
    { key: 'imap_setting.address', label: with_imap_prefix(Webmail::ImapSetting.t('address')) },
    { key: 'imap_setting.imap_alias', label: with_imap_prefix(Webmail::ImapSetting.t('imap_alias')) },
    { key: 'imap_setting.imap_host', label: with_imap_prefix(Webmail::ImapSetting.t('imap_host')) },
    { key: 'imap_setting.imap_port', label: with_imap_prefix(Webmail::ImapSetting.t('imap_port')) },
    { key: 'imap_setting.imap_ssl_use', label: with_imap_prefix(Webmail::ImapSetting.t('imap_ssl_use')) },
    { key: 'imap_setting.imap_auth_type', label: with_imap_prefix(Webmail::ImapSetting.t('imap_auth_type')) },
    { key: 'imap_setting.imap_account', label: with_imap_prefix(Webmail::ImapSetting.t('imap_account')) },
    { key: 'imap_setting.imap_password', label: with_imap_prefix(Webmail::ImapSetting.t('imap_password')), getter: :none },
    { key: 'imap_setting.threshold_mb', label: with_imap_prefix(Webmail::ImapSetting.t('threshold_mb')) },
    { key: 'imap_setting.imap_sent_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_sent_box')) },
    { key: 'imap_setting.imap_draft_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_draft_box')) },
    { key: 'imap_setting.imap_trash_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_trash_box')) },
    { key: 'imap_setting.default', label: with_imap_prefix(Webmail::ImapSetting.t('default')) }
  ].freeze
  EXPORT_DEF = BASE_ATTRIBUTES + IMAP_SETTING_ATTRIBUTES
  IMPORT_DEF = IMAP_SETTING_ATTRIBUTES
end
