class Webmail::GroupExport
  include ActiveModel::Model
  extend SS::Translation
  include SS::PermitParams

  def self.with_imap_prefix(label)
    return label if label.start_with?("IMAP/")
    "IMAP/#{label}"
  end

  EXPORT_DEF = [
    # SS::Model::Group
    { key: 'id', label: Webmail::Group.t('id'), setter: :none }.freeze,
    { key: 'name', label: Webmail::Group.t('name') }.freeze,
    { key: 'domains', label: Webmail::Group.t('domains') }.freeze,
    { key: 'order', label: Webmail::Group.t('order') }.freeze,
    { key: 'activation_date', label: Webmail::Group.t('activation_date') }.freeze,
    { key: 'expiration_date', label: Webmail::Group.t('expiration_date') }.freeze,
    # Ldap::Addon::Group
    { key: 'ldap_dn', label: Webmail::Group.t('ldap_dn') }.freeze,
    # Contact::Addon::Group
    { key: 'contact_tel', label: Webmail::Group.t('contact_tel') }.freeze,
    { key: 'contact_fax', label: Webmail::Group.t('contact_fax') }.freeze,
    { key: 'contact_email', label: Webmail::Group.t('contact_email') }.freeze,
    { key: 'contact_link_url', label: Webmail::Group.t('contact_link_url') }.freeze,
    { key: 'contact_link_name', label: Webmail::Group.t('contact_link_name') }.freeze,
    # Webmail::Addon::GroupExtension
    { key: 'imap_setting.name', label: with_imap_prefix(Webmail::ImapSetting.t('name')) }.freeze,
    { key: 'imap_setting.from', label: with_imap_prefix(Webmail::ImapSetting.t('from')) }.freeze,
    { key: 'imap_setting.address', label: with_imap_prefix(Webmail::ImapSetting.t('address')) }.freeze,
    { key: 'imap_setting.imap_host', label: with_imap_prefix(Webmail::ImapSetting.t('imap_host')) }.freeze,
    { key: 'imap_setting.imap_port', label: with_imap_prefix(Webmail::ImapSetting.t('imap_port')) }.freeze,
    { key: 'imap_setting.imap_ssl_use', label: with_imap_prefix(Webmail::ImapSetting.t('imap_ssl_use')) }.freeze,
    { key: 'imap_setting.imap_auth_type', label: with_imap_prefix(Webmail::ImapSetting.t('imap_auth_type')) }.freeze,
    { key: 'imap_setting.imap_account', label: with_imap_prefix(Webmail::ImapSetting.t('imap_account')) }.freeze,
    { key: 'imap_setting.imap_password', label: with_imap_prefix(Webmail::ImapSetting.t('imap_password')) }.freeze,
    { key: 'imap_setting.threshold_mb', label: with_imap_prefix(Webmail::ImapSetting.t('threshold_mb')) }.freeze,
    { key: 'imap_setting.imap_sent_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_sent_box')) }.freeze,
    { key: 'imap_setting.imap_draft_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_draft_box')) }.freeze,
    { key: 'imap_setting.imap_trash_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_trash_box')) }.freeze,
  ].freeze

  attr_accessor :cur_user, :in_file

  permit_params :in_file

  def export_csv(items)
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << EXPORT_DEF.map { |export_def| export_def[:label] }
        items.each do |item|
          setting = item.imap_settings.first
          data << EXPORT_DEF.map do |export_def|
            export_field(item, 0, setting, export_def)
          end
        end
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_template_csv(items)
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << EXPORT_DEF.map { |export_def| export_def[:label] }
        items.each do |item|
          data << EXPORT_DEF.map do |export_def|
            export_field(item, 0, nil, export_def)
          end
        end
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    SS::Csv.foreach_row(in_file, headers: true) do |row, index|
      update_row(row, index)
    end
    errors.empty?
  end

  private

  def update_row(row, index)
    id = str(row, 'id')
    if id.present?
      item = Webmail::Group.allow(:read, @cur_user).where(id: id).first
      if item.blank?
        errors.add :base, "#{index + 1}: Could not find ##{id}"
        return
      end
    else
      name = str(row, 'name')
      if name.present?
        item = Webmail::Group.allow(:read, @cur_user).where(name: name).first
      end
      item ||= Webmail::Group.new
    end

    if !item.allowed?(:edit, @cur_user)
      errors.add :base, "#{index + 1}: #{I18n.t('errors.messages.auth_error')}"
      return
    end

    setting = item.imap_settings[0]
    setting ||= Webmail::ImapSetting.default

    EXPORT_DEF.each { |export_def| import_field(row, item, setting, export_def) }

    if setting[:name].present?
      setting.set_imap_password
      if setting.invalid?(:group)
        SS::Model.copy_errors(setting, self, prefix: "#{index + 1}: ")
        return
      end

      item.imap_settings = [ setting ]
    else
      item.imap_settings = []
    end

    if !item.save
      SS::Model.copy_errors(item, self, prefix: "#{index + 1}: ")
      return
    end

    item
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    unmatched = 0
    SS::Csv.foreach_row(in_file, headers: true) do |row|
      EXPORT_DEF.each do |export_def|
        unmatched += 1 if !row.key?(export_def[:label])
      end
      break
    end

    errors.add :in_file, :invalid_file_type if unmatched > 4
    in_file.rewind
  rescue
    errors.add :in_file, :invalid_file_type
  end

  def str(row, key)
    label = key.to_s
    export_def = EXPORT_DEF.find { |export_def| export_def[:key].to_s == label }
    if export_def.present?
      label = export_def[:label]
    end
    row[label].to_s.strip
  end

  def export_field(item, index, setting, export_def)
    getter = export_def[:getter]
    if getter.nil?
      method = "get_item_#{export_def[:key].tr(".", "_")}".to_sym
      getter = method if respond_to?(method, true)
    end
    if getter.nil?
      getter = method(:get_item_field).curry.call(export_def[:key])
    end

    if getter.is_a?(Symbol)
      send(getter, item, index, setting)
    else
      getter.call(item, index, setting)
    end
  end

  def get_item_field(field_name, item, index, setting)
    val = item
    field_name.split(".").each do |f|
      if f == "imap_setting"
        val = setting
      else
        val = val.send(f)
      end
      break if val.nil?
    end

    return if val.nil?

    if val.is_a?(Date) || val.is_a?(Time)
      return I18n.l(val)
    end

    val.to_s
  end

  def get_item_imap_setting_imap_ssl_use(item, index, setting)
    return if setting.nil?
    setting.imap_ssl_use.present? ? I18n.t("webmail.options.imap_ssl_use.#{setting.imap_ssl_use}") : nil
  end

  def get_item_imap_setting_imap_password(item, index, setting)
    return if setting.nil?
    setting.in_imap_password
  end

  def import_field(row, item, setting, export_def)
    setter = export_def[:setter]
    if setter.nil?
      method = "set_item_#{export_def[:key].tr(".", "_")}".to_sym
      setter = method if respond_to?(method, true)
    end
    if setter.nil?
      setter = method(:set_item_field).curry.call(export_def[:key])
    end

    if setter.is_a?(Symbol)
      return if setter == :none
      send(setter, row, item, setting)
    else
      setter.call(row, item, setting)
    end
  end

  def set_item_field(field_name, row, item, setting)
    names = field_name.split(".")
    setter = names.pop

    target = item
    names.each do |f|
      if f == "imap_setting"
        target = setting
      else
        target = target.send(f)
      end
      break if target.nil?
    end

    target.send("#{setter}=", str(row, field_name))
  end

  def set_item_imap_setting_name(row, item, setting)
    setting[:name] = str(row, 'imap_setting.name').presence
  end

  def set_item_imap_setting_from(row, item, setting)
    setting[:from] = str(row, 'imap_setting.from')
  end

  def set_item_imap_setting_address(row, item, setting)
    setting[:address] = str(row, 'imap_setting.address')
  end

  def set_item_imap_setting_imap_host(row, item, setting)
    setting[:imap_host] = str(row, 'imap_setting.imap_host')
  end

  def set_item_imap_setting_imap_port(row, item, setting)
    setting[:imap_port] = str(row, 'imap_setting.imap_port')
  end

  def set_item_imap_setting_imap_ssl_use(row, item, setting)
    ssl_use = str(row, 'imap_setting.imap_ssl_use').presence
    if ssl_use.present?
      key_value = I18n.t("webmail.options.imap_ssl_use").to_a.find { |key, value| value == ssl_use }
      ssl_use = key_value.present? ? key_value[0].to_s : nil
    end

    setting[:imap_ssl_use] = ssl_use
  end

  def set_item_imap_setting_imap_auth_type(row, item, setting)
    setting[:imap_auth_type] = str(row, 'imap_setting.imap_auth_type')
  end

  def set_item_imap_setting_imap_account(row, item, setting)
    setting[:imap_account] = str(row, 'imap_setting.imap_account')
  end

  def set_item_imap_setting_imap_password(row, item, setting)
    pass = str(row, 'imap_setting.imap_password')
    if pass.present?
      setting[:in_imap_password] = pass
    else
      setting[:imap_password] = nil
    end
  end

  def set_item_imap_setting_threshold_mb(row, item, setting)
    setting[:threshold_mb] = str(row, 'imap_setting.threshold_mb')
  end

  def set_item_imap_setting_imap_sent_box(row, item, setting)
    setting[:imap_sent_box] = str(row, 'imap_setting.imap_sent_box')
  end

  def set_item_imap_setting_imap_draft_box(row, item, setting)
    setting[:imap_draft_box] = str(row, 'imap_setting.imap_draft_box')
  end

  def set_item_imap_setting_imap_trash_box(row, item, setting)
    setting[:imap_trash_box] = str(row, 'imap_setting.imap_trash_box')
  end
end
