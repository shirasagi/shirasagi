class Webmail::AccountExport
  include ActiveModel::Model
  extend SS::Translation
  include SS::PermitParams

  EXPORT_DEF = [
    # SS::Model::User
    { key: 'id', label: Webmail::User.t('id'), setter: :none }.freeze,
    { key: 'uid', label: Webmail::User.t('uid'), setter: :none }.freeze,
    { key: 'organization_uid', label: Webmail::User.t('organization_uid'), setter: :none }.freeze,
    # Webmail::UserExtension
    { key: 'imap_setting.account_index', label: Webmail::User.t('account_index'), setter: :none }.freeze,
    { key: 'imap_setting.name', label: Webmail::ImapSetting.t('name') }.freeze,
    { key: 'imap_setting.from', label: Webmail::ImapSetting.t('from') }.freeze,
    { key: 'imap_setting.address', label: Webmail::ImapSetting.t('address') }.freeze,
    { key: 'imap_setting.imap_alias', label: Webmail::ImapSetting.t('imap_alias') }.freeze,
    { key: 'imap_setting.imap_host', label: Webmail::ImapSetting.t('imap_host') }.freeze,
    { key: 'imap_setting.imap_port', label: Webmail::ImapSetting.t('imap_port') }.freeze,
    { key: 'imap_setting.imap_ssl_use', label: Webmail::ImapSetting.t('imap_ssl_use') }.freeze,
    { key: 'imap_setting.imap_auth_type', label: Webmail::ImapSetting.t('imap_auth_type') }.freeze,
    { key: 'imap_setting.imap_account', label: Webmail::ImapSetting.t('imap_account') }.freeze,
    { key: 'imap_setting.imap_password', label: Webmail::ImapSetting.t('imap_password') }.freeze,
    { key: 'imap_setting.threshold_mb', label: Webmail::ImapSetting.t('threshold_mb') }.freeze,
    { key: 'imap_setting.imap_sent_box', label: Webmail::ImapSetting.t('imap_sent_box') }.freeze,
    { key: 'imap_setting.imap_draft_box', label: Webmail::ImapSetting.t('imap_draft_box') }.freeze,
    { key: 'imap_setting.imap_trash_box', label: Webmail::ImapSetting.t('imap_trash_box') }.freeze,
    { key: 'imap_setting.default', label: Webmail::ImapSetting.t('default') }.freeze,
  ].freeze

  attr_accessor :cur_user, :in_file
  permit_params :in_file

  def export_csv(items)
    csv = CSV.generate do |data|
      data << EXPORT_DEF.map { |export_def| export_def[:label] }
      items.each do |item|
        item.imap_settings.each_with_index do |setting, i|
          line = EXPORT_DEF.map do |export_def|
            export_field(item, i, setting, export_def)
          end
          data << line
        end
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_template_csv(items)
    csv = CSV.generate do |data|
      data << EXPORT_DEF.map { |export_def| export_def[:label] }
      items.each do |item|
        setting = Webmail::ImapSetting.default
        line = EXPORT_DEF.map do |export_def|
          export_field(item, 0, setting, export_def)
        end
        data << line
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    index = 0
    CSV.foreach(in_file.path, headers: true, encoding: 'SJIS:UTF-8') do |row|
      update_row(row, index)
      index += 1
    end
    errors.empty?
  end

  private

  def update_row(row, index)
    id = str(row, 'id')
    if id.blank?
      errors.add :base, "#{index + 1}: #{Webmail::User.t('id')} is required"
      return
    end

    account_index = str(row, 'imap_setting.account_index')
    if !account_index.numeric?
      errors.add :base, "#{index + 1}: #{Webmail::User.t('account_index')} is required"
      return
    end

    account_index = account_index.to_i
    account_index -= 1
    if account_index < 0
      errors.add :base, "#{index + 1}: #{Webmail::User.t('account_index')} should be greater than 0"
      return
    end

    item = Webmail::User.allow(:read, @cur_user).where(id: id).first
    if item.blank?
      errors.add :base, "#{index + 1}: Could not find ##{id}"
      return
    end

    if !item.allowed?(:edit, @cur_user)
      errors.add :base, "#{index + 1}: #{I18n.t('errors.messages.auth_error')}"
      return
    end

    setting = item.imap_settings[account_index]
    setting ||= Webmail::ImapSetting.default

    EXPORT_DEF.each { |export_def| import_field(row, item, setting, export_def) }

    if setting.invalid?
      setting.errors.full_messages.each do |msg|
        errors.add :base, "#{index + 1}: #{msg}"
      end
      return
    end

    imap_settings = item.imap_settings.to_a
    imap_settings[account_index] = setting
    imap_settings = imap_settings.compact
    item.imap_settings = imap_settings

    item.cur_user = @cur_user
    if !item.save
      item.errors.full_messages.each do |msg|
        errors.add :base, "#{index + 1}: #{msg}"
      end
      return
    end

    item
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i

    unmatched = 0
    CSV.foreach(in_file.path, headers: true, encoding: 'SJIS:UTF-8') do |row|
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

  def get_item_imap_setting_account_index(item, index, setting)
    index + 1
  end

  def get_item_imap_setting_imap_ssl_use(item, index, setting)
    setting.imap_ssl_use.present? ? I18n.t("webmail.options.imap_ssl_use.#{setting.imap_ssl_use}") : nil
  end

  def get_item_imap_setting_default(item, index, setting)
    index == item.imap_default_index ? index + 1 : nil
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
end
