class Webmail::GroupExporter
  include SS::GroupExporterBase

  self.mode = :webmail
  attr_accessor :template

  def self.with_imap_prefix(attr)
    label = Webmail::ImapSetting.t(attr)
    if label.start_with?("IMAP/")
      label.sub("/", "_")
    else
      "IMAP_#{label}"
    end
  end

  private

  def draw_exporters(drawer)
    super
    draw_imap(drawer)
  end

  IMAP_SETTING_ATTRIBUTES = %i[
    name from address imap_host imap_port imap_ssl_use imap_auth_type imap_account imap_password
    imap_sent_box imap_draft_box imap_trash_box threshold_mb
  ].freeze

  # Webmail::Addon::GroupExtension
  def draw_imap(drawer)
    template = self.template
    IMAP_SETTING_ATTRIBUTES.each do |attr|
      drawer.column "imap_#{attr}" do
        drawer.head { self.class.with_imap_prefix(attr) }
        unless template
          drawer.body { |item| send("imap_setting_#{attr}", item, attr) }
        end
      end
    end
  end

  def imap_setting_name(item, attr)
    item.imap_settings.first.try(attr)
  end
  alias imap_setting_from imap_setting_name
  alias imap_setting_address imap_setting_name
  alias imap_setting_imap_host imap_setting_name
  alias imap_setting_imap_port imap_setting_name
  alias imap_setting_imap_auth_type imap_setting_name
  alias imap_setting_imap_account imap_setting_name
  alias imap_setting_imap_sent_box imap_setting_name
  alias imap_setting_imap_draft_box imap_setting_name
  alias imap_setting_imap_trash_box imap_setting_name
  alias imap_setting_threshold_mb imap_setting_name

  def imap_setting_imap_ssl_use(item, _attr)
    if setting = item.imap_settings.first
      setting.imap_ssl_use.present? ? I18n.t("webmail.options.imap_ssl_use.#{setting.imap_ssl_use}") : nil
    end
  end

  def imap_setting_imap_password(item, _attr)
    if setting = item.imap_settings.first
      setting.in_imap_password
    end
  end
end
