class Webmail::AccountExport
  include ActiveModel::Model
  extend SS::Translation
  include SS::PermitParams

  ACCOUNT_EXPORT_DEF = [
    { key: 'id', label: Webmail::User.t('id'), getter: proc { |item| item.id } }.freeze,
    { key: 'uid', label: Webmail::User.t('uid'), getter: proc { |item| item.uid } }.freeze,
    { key: 'organization_uid', label: Webmail::User.t('organization_uid'),
      getter: proc { |item| item.organization_uid } }.freeze,
    { key: 'account_index', label: Webmail::User.t('account_index'),
      getter: ->(item, index, setting){ index + 1 } }.freeze,
    { key: 'name', label: Webmail::ImapSetting.t('name'),
      getter: ->(item, index, setting){ setting.name }, setter: :set_item_imap_name }.freeze,
    { key: 'from', label: Webmail::ImapSetting.t('from'),
      getter: ->(item, index, setting){ setting.from }, setter: :set_item_imap_from }.freeze,
    { key: 'address', label: Webmail::ImapSetting.t('address'),
      getter: ->(item, index, setting){ setting.address }, setter: :set_item_imap_address }.freeze,
    { key: 'imap_alias', label: Webmail::ImapSetting.t('imap_alias'),
      getter: ->(item, index, setting){ setting.imap_alias }, setter: :set_item_imap_alias }.freeze,
    { key: 'imap_host', label: Webmail::ImapSetting.t('imap_host'),
      getter: ->(item, index, setting){ setting.imap_host }, setter: :set_item_imap_host }.freeze,
    { key: 'imap_port', label: Webmail::ImapSetting.t('imap_port'),
      getter: ->(item, index, setting){ setting.imap_port }, setter: :set_item_imap_port }.freeze,
    { key: 'imap_ssl_use', label: Webmail::ImapSetting.t('imap_ssl_use'),
      getter: :get_item_imap_ssl_use, setter: :set_item_imap_ssl_use }.freeze,
    { key: 'imap_auth_type', label: Webmail::ImapSetting.t('imap_auth_type'),
      getter: ->(item, index, setting){ setting.imap_auth_type }, setter: :set_item_imap_auth_type }.freeze,
    { key: 'imap_account', label: Webmail::ImapSetting.t('imap_account'),
      getter: ->(item, index, setting){ setting.imap_account }, setter: :set_item_imap_account }.freeze,
    { key: 'imap_password', label: Webmail::ImapSetting.t('imap_password'),
      getter: ->(item, index, setting){ setting.in_imap_password }, setter: :set_item_imap_password }.freeze,
    { key: 'threshold_mb', label: Webmail::ImapSetting.t('threshold_mb'),
      getter: ->(item, index, setting){ setting.threshold_mb }, setter: :set_item_imap_threshold_mb }.freeze,
    { key: 'imap_sent_box', label: Webmail::ImapSetting.t('imap_sent_box'),
      getter: ->(item, index, setting){ setting.imap_sent_box }, setter: :set_item_imap_sent_box }.freeze,
    { key: 'imap_draft_box', label: Webmail::ImapSetting.t('imap_draft_box'),
      getter: ->(item, index, setting){ setting.imap_draft_box }, setter: :set_item_imap_draft_box }.freeze,
    { key: 'imap_trash_box', label: Webmail::ImapSetting.t('imap_trash_box'),
      getter: ->(item, index, setting){ setting.imap_trash_box }, setter: :set_item_imap_trash_box }.freeze,
    { key: 'default', label: Webmail::ImapSetting.t('default'),
      getter: :get_item_imap_default, setter: :set_item_imap_default }.freeze,
  ].freeze

  attr_accessor :cur_user, :in_file
  permit_params :in_file

  def export_csv(items)
    csv = CSV.generate do |data|
      data << ACCOUNT_EXPORT_DEF.map { |d| d[:label] }
      items.each do |item|
        item.imap_settings.each_with_index do |setting, i|
          line = ACCOUNT_EXPORT_DEF.map do |d|
            getter = d[:getter]
            if getter.is_a?(Symbol)
              send(getter, item, i, setting)
            else
              getter.call(item, i, setting)
            end
          end
          data << line
        end
      end
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_template_csv(items)
    csv = CSV.generate do |data|
      data << ACCOUNT_EXPORT_DEF.map { |d| d[:label] }
      items.each do |item|
        setting = Webmail::ImapSetting.new
        line = ACCOUNT_EXPORT_DEF.map do |d|
          invoke d[:getter], item, 0, setting
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

  def update_row(row, index)
    id = str(row, 'id')
    if id.blank?
      errors.add :base, "#{index + 1}: #{Webmail::User.t('id')} is required"
      return
    end

    account_index = str(row, 'account_index')
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

    ACCOUNT_EXPORT_DEF.each { |d| invoke(d[:setter], row, item, setting) }

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

  private

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    return errors.add :in_file, :invalid_file_type if ::File.extname(fname) !~ /^\.csv$/i

    unmatched = 0
    CSV.foreach(in_file.path, headers: true, encoding: 'SJIS:UTF-8') do |row|
      ACCOUNT_EXPORT_DEF.each do |d|
        unmatched += 1 if !row.key?(d[:label])
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
    d = ACCOUNT_EXPORT_DEF.find { |d| d[:key].to_s == label }
    if d.present?
      label = d[:label]
    end
    row[label].to_s.strip
  end

  def invoke(method, *args)
    return if method.blank?

    if method.is_a?(Symbol)
      send(method, *args)
    else
      method.call(*args)
    end
  end

  def set_item_imap_name(row, item, setting)
    setting[:name] = str(row, 'name')
  end

  def set_item_imap_from(row, item, setting)
    setting[:from] = str(row, 'from')
  end

  def set_item_imap_address(row, item, setting)
    setting[:address] = str(row, 'address')
  end

  def set_item_imap_alias(row, item, setting)
    setting[:imap_alias] = str(row, 'imap_alias')
  end

  def set_item_imap_host(row, item, setting)
    setting[:imap_host] = str(row, 'imap_host')
  end

  def set_item_imap_port(row, item, setting)
    setting[:imap_port] = str(row, 'imap_port')
  end

  def get_item_imap_ssl_use(item, index, setting)
    setting.imap_ssl_use.present? ? I18n.t("webmail.options.imap_ssl_use.#{setting.imap_ssl_use}") : nil
  end

  def set_item_imap_ssl_use(row, item, setting)
    ssl_use = str(row, 'imap_ssl_use').presence
    if ssl_use.present?
      key_value = I18n.t("webmail.options.imap_ssl_use").to_a.find { |key, value| value == ssl_use }
      ssl_use = key_value.present? ? key_value[0].to_s : nil
    end

    setting[:imap_ssl_use] = ssl_use
  end

  def set_item_imap_auth_type(row, item, setting)
    setting[:imap_auth_type] = str(row, 'imap_auth_type')
  end

  def set_item_imap_account(row, item, setting)
    setting[:imap_account] = str(row, 'imap_account')
  end

  def set_item_imap_password(row, item, setting)
    pass = str(row, 'imap_password')
    if pass.present?
      setting[:in_imap_password] = pass
    else
      setting[:imap_password] = nil
    end
  end

  def set_item_imap_threshold_mb(row, item, setting)
    setting[:threshold_mb] = str(row, 'threshold_mb')
  end

  def set_item_imap_sent_box(row, item, setting)
    setting[:imap_sent_box] = str(row, 'imap_sent_box')
  end

  def set_item_imap_draft_box(row, item, setting)
    setting[:imap_draft_box] = str(row, 'imap_draft_box')
  end

  def set_item_imap_trash_box(row, item, setting)
    setting[:imap_trash_box] = str(row, 'imap_trash_box')
  end

  def get_item_imap_default(item, index, setting)
    index == item.imap_default_index ? index + 1 : nil
  end

  def set_item_imap_default(row, item, setting)
    return if str(row, 'default').blank?
    item.imap_default_index = str(row, 'account_index').to_i - 1
  end
end
