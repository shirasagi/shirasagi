class Webmail::GroupImportJob < Webmail::ApplicationJob
  include SS::GroupImportBase

  self.mode = :webmail
  self.model = Webmail::Group

  set_callback :import_row, :before do
    @setting = @item.imap_settings[0]
    @setting ||= Webmail::ImapSetting.new
  end
  set_callback :import_row, :after do
    if @setting[:name].present?
      @setting.set_imap_password
      if @setting.invalid?(:group)
        SS::Model.copy_errors(@setting, @item, prefix: "#{@item.name}: ")
        next
      end

      @item.imap_settings = [ @setting ]
    else
      @item.imap_settings = []
    end
  ensure
    @setting = nil
  end

  def self.with_imap_prefix(attr)
    label = Webmail::ImapSetting.t(attr)
    if label.start_with?("IMAP/")
      label.sub("/", "_")
    else
      "IMAP_#{label}"
    end
  end

  private

  def define_importers(importer)
    super
    define_importer_imap(importer)
  end

  IMAP_SETTING_ATTRIBUTES = %i[
    name from address imap_host imap_port imap_ssl_use imap_auth_type imap_account imap_password
    imap_sent_box imap_draft_box imap_trash_box threshold_mb
  ].freeze

  def define_importer_imap(importer)
    IMAP_SETTING_ATTRIBUTES.each do |attr|
      importer.simple_column "imap_#{attr}", name: self.class.with_imap_prefix(attr) do |row, item, head, value|
        send("imap_setting_#{attr}", item, attr, value)
      end
    end
  end

  def imap_setting_name(_item, attr, value)
    @setting[attr] = value.presence
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

  def imap_setting_imap_ssl_use(item, _attr, value)
    value = from_label(value, item.imap_ssl_use_options)
    @setting[:imap_ssl_use] = value.presence
  end

  def imap_setting_imap_password(_item, _attr, value)
    if value.present?
      @setting[:in_imap_password] = value.presence
    else
      @setting[:imap_password] = nil
    end
  end

  def find_or_initialize_item(row)
    id = value(row, :id)
    if id.present?
      item = Webmail::Group.where(id: id).first
      if item.blank?
        Rails.logger.warn { "Could not find ##{id}" }
        return
      end
      item
    else
      name = value(row, :name)
      if name.present?
        item = Webmail::Group.where(name: name).first
      end
      item || Webmail::Group.new
    end
  end
end
