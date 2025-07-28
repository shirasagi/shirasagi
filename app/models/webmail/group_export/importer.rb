class Webmail::GroupExport::Importer < Webmail::GroupExport::Base

  attr_accessor :cur_user, :in_file

  def import_csv
    validate_import_file
    return false unless errors.empty?

    SS::Csv.foreach_row(in_file, headers: true) do |row, index|
      update_row(row, index)
    end
    result = errors.empty?

    purge_webmail_caches

    result
  end

  private

  def str(row, key)
    label = key.to_s
    import_def = IMPORT_DEF.find { |import_def| import_def[:key].to_s == label }
    if import_def.present?
      label = import_def[:label]
    end
    row[label].to_s.strip
  end

  def import_field(row, item, setting, import_def)
    setter = import_def[:setter]
    if setter.nil?
      method = "set_item_#{import_def[:key].tr(".", "_")}".to_sym
      setter = method if respond_to?(method, true)
    end
    if setter.nil?
      setter = method(:set_item_field).curry.call(import_def[:key])
    end

    if setter.is_a?(Symbol)
      return if setter == :none
      send(setter, row, item, setting)
    else
      setter.call(row, item, setting)
    end
  end

  def set_item_field(field_name, row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

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
    setting[:name] = str(row, 'imap_setting.name')
  end

  def set_item_imap_setting_from(row, item, setting)
    setting[:from] = str(row, 'imap_setting.from')
  end

  def set_item_imap_setting_address(row, item, setting)
    setting[:address] = str(row, 'imap_setting.address')
  end

  def set_item_imap_setting_imap_alias(row, item, setting)
    setting[:imap_alias] = str(row, 'imap_setting.imap_alias')
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

  def set_item_imap_setting_default(row, item, setting)
    return if str(row, 'imap_setting.default').blank?
    item.imap_default_index = str(row, 'imap_setting.account_index').to_i - 1
  end

  def update_row(row, index)
    id = str(row, 'id')

    if id.blank?
      errors.add :base, "#{index + 1}: id not find"
      return
    end

    item = Webmail::Group.allow(:read, @cur_user).where(id: id).first
    if item.blank?
      errors.add :base, "#{index + 1}: Could not find ##{id}"
      return
    end

    if !item.allowed?(:edit, @cur_user)
      errors.add :base, "#{index + 1}: #{I18n.t('errors.messages.auth_error')}"
      return
    end

    account_index = str(row, 'imap_setting.account_index')
    if !account_index.numeric?
      errors.add :base, "#{index + 1}: #{Webmail::Group.t('account_index')} is required"
      return
    end

    account_index = account_index.to_i
    account_index -= 1
    if account_index < 0
      errors.add :base, "#{index + 1}: #{Webmail::Group.t('account_index')} should be greater than 0"
      return
    end

    setting = item.imap_settings[account_index]
    setting ||= Webmail::ImapSetting.default

    IMPORT_DEF.each { |import_def| import_field(row, item, setting, import_def) }

    setting.set_imap_password
    if setting.invalid?
      SS::Model.copy_errors(setting, self, prefix: "#{index + 1}: ")
      return
    end

    imap_settings = item.imap_settings.to_a
    imap_settings[account_index] = setting
    imap_settings = imap_settings.compact
    item.imap_settings = imap_settings

    if !item.save
      SS::Model.copy_errors(item, self, prefix: "#{index + 1}: ")
      return
    end

    item
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    if in_file.respond_to?(:original_filename)
      fname = in_file.original_filename
    else
      fname = in_file.filename
    end

    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    if !self.class.valid_csv?(in_file)
      errors.add :in_file, :invalid_file_type
    end
  end

  def purge_webmail_caches
    Webmail::Mail.all.find_each(&:destroy_rfc822)
    Webmail::Mail.all.delete_all
    Webmail::Mailbox.all.delete_all
  end

  class << self
    def valid_csv?(file)
      I18n.with_locale(I18n.default_locale) do
        headers = self::EXPORT_DEF.map { |export_def| export_def[:label] }
        SS::Csv.valid_csv?(file, headers: true, required_headers: headers)
      end
    end
  end
end
