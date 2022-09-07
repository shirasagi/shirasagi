class Webmail::UserExport
  include ActiveModel::Model
  extend SS::Translation
  include SS::PermitParams

  def self.with_imap_prefix(label)
    return label if label.start_with?("IMAP/")
    "IMAP/#{label}"
  end

  EXPORT_DEF = [
    # SS::Model::User
    { key: 'id', label: Webmail::User.t('id'), setter: :none }.freeze,
    { key: 'name', label: Webmail::User.t('name') }.freeze,
    { key: 'kana', label: Webmail::User.t('kana') }.freeze,
    { key: 'uid', label: Webmail::User.t('uid') }.freeze,
    { key: 'organization_uid', label: Webmail::User.t('organization_uid') }.freeze,
    { key: 'email', label: Webmail::User.t('email') }.freeze,
    { key: 'password', label: Webmail::User.t('password'), getter: :none }.freeze,
    { key: 'tel', label: Webmail::User.t('tel') }.freeze,
    { key: 'tel_ext', label: Webmail::User.t('tel_ext') }.freeze,
    { key: 'type', label: Webmail::User.t('type') }.freeze,
    { key: 'account_start_date', label: Webmail::User.t('account_start_date') }.freeze,
    { key: 'account_expiration_date', label: Webmail::User.t('account_expiration_date') }.freeze,
    { key: 'initial_password_warning', label: Webmail::User.t('initial_password_warning') }.freeze,
    { key: 'session_lifetime', label: Webmail::User.t('session_lifetime') }.freeze,
    { key: 'restriction', label: Webmail::User.t('restriction') }.freeze,
    { key: 'lock_state', label: Webmail::User.t('lock_state') }.freeze,
    { key: 'organization_id', label: Webmail::User.t('organization_id') }.freeze,
    { key: 'group_ids', label: Webmail::User.t('group_ids') }.freeze,
    { key: 'remark', label: Webmail::User.t('remark') }.freeze,
    # Ldap::Addon::Group
    { key: 'ldap_dn', label: Webmail::User.t('ldap_dn') }.freeze,
    # Webmail::Addon::Role
    { key: 'webmail_role_ids', label: I18n.t("mongoid.attributes.ss/model/user.webmail_role_ids") }.freeze,
    # Sys::Reference::Role
    { key: 'sys_role_ids', label: I18n.t("mongoid.attributes.ss/model/user.sys_role_ids") }.freeze,
    # Webmail::UserExtension
    { key: 'imap_setting.account_index', label: with_imap_prefix(Webmail::User.t('account_index')), setter: :none }.freeze,
    { key: 'imap_setting.name', label: with_imap_prefix(Webmail::ImapSetting.t('name')) }.freeze,
    { key: 'imap_setting.from', label: with_imap_prefix(Webmail::ImapSetting.t('from')) }.freeze,
    { key: 'imap_setting.address', label: with_imap_prefix(Webmail::ImapSetting.t('address')) }.freeze,
    { key: 'imap_setting.imap_alias', label: with_imap_prefix(Webmail::ImapSetting.t('imap_alias')) }.freeze,
    { key: 'imap_setting.imap_host', label: with_imap_prefix(Webmail::ImapSetting.t('imap_host')) }.freeze,
    { key: 'imap_setting.imap_port', label: with_imap_prefix(Webmail::ImapSetting.t('imap_port')) }.freeze,
    { key: 'imap_setting.imap_ssl_use', label: with_imap_prefix(Webmail::ImapSetting.t('imap_ssl_use')) }.freeze,
    { key: 'imap_setting.imap_auth_type', label: with_imap_prefix(Webmail::ImapSetting.t('imap_auth_type')) }.freeze,
    { key: 'imap_setting.imap_account', label: with_imap_prefix(Webmail::ImapSetting.t('imap_account')) }.freeze,
    { key: 'imap_setting.imap_password', label: with_imap_prefix(Webmail::ImapSetting.t('imap_password')), getter: :none }.freeze,
    { key: 'imap_setting.threshold_mb', label: with_imap_prefix(Webmail::ImapSetting.t('threshold_mb')) }.freeze,
    { key: 'imap_setting.imap_sent_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_sent_box')) }.freeze,
    { key: 'imap_setting.imap_draft_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_draft_box')) }.freeze,
    { key: 'imap_setting.imap_trash_box', label: with_imap_prefix(Webmail::ImapSetting.t('imap_trash_box')) }.freeze,
    { key: 'imap_setting.default', label: with_imap_prefix(Webmail::ImapSetting.t('default')) }.freeze,
  ].freeze

  attr_accessor :cur_user, :in_file

  permit_params :in_file

  def export_csv(items)
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
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
    end
    csv.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def export_template_csv(items)
    csv = I18n.with_locale(I18n.default_locale) do
      CSV.generate do |data|
        data << EXPORT_DEF.map { |export_def| export_def[:label] }
        items.each do |item|
          setting = Webmail::ImapSetting.default
          line = EXPORT_DEF.map do |export_def|
            export_field(item, 0, setting, export_def)
          end
          data << line
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
    result = errors.empty?

    purge_webmail_caches

    result
  end

  private

  def update_row(row, index)
    id = str(row, 'id')
    if id.present?
      item = Webmail::User.allow(:read, @cur_user).where(id: id).first
      if item.blank?
        errors.add :base, "#{index + 1}: Could not find ##{id}"
        return
      end
    else
      uid = str(row, 'uid')
      if uid.present?
        item = Webmail::User.allow(:read, @cur_user).where(uid: uid).first
      end

      email = str(row, 'uid')
      if item.blank? && email.present?
        item = Webmail::User.allow(:read, @cur_user).where(email: email).first
      end

      item ||= Webmail::User.new
    end

    if !item.allowed?(:edit, @cur_user)
      errors.add :base, "#{index + 1}: #{I18n.t('errors.messages.auth_error')}"
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

    setting = item.imap_settings[account_index]
    setting ||= Webmail::ImapSetting.default

    EXPORT_DEF.each { |export_def| import_field(row, item, setting, export_def) }

    setting.set_imap_password
    if setting.invalid?
      SS::Model.copy_errors(setting, self, prefix: "#{index + 1}: ")
      return
    end

    imap_settings = item.imap_settings.to_a
    imap_settings[account_index] = setting
    imap_settings = imap_settings.compact
    item.imap_settings = imap_settings

    item.cur_user = @cur_user
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
      return if getter == :none
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

  def get_item_type(item, index, setting)
    item.label(:type)
  end

  def get_item_initial_password_warning(item, index, setting)
    item.label(:initial_password_warning)
  end

  def get_item_restriction(item, index, setting)
    item.label(:restriction)
  end

  def get_item_lock_state(item, index, setting)
    item.label(:lock_state)
  end

  def get_item_organization_id(item, index, setting)
    item.organization.try(:name)
  end

  def get_item_group_ids(item, index, setting)
    item.groups.pluck(:name).join("\n")
  end

  def get_item_webmail_role_ids(item, index, setting)
    item.webmail_roles.pluck(:name).join("\n")
  end

  def get_item_sys_role_ids(item, index, setting)
    item.sys_roles.and_general.pluck(:name).join("\n")
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

  def set_item_password(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    password = str(row, 'password')
    item.in_password = password if password.present?
  end

  def set_item_type(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    type = str(row, 'type')
    option = item.type_options.find { |option| option[0] == type }
    item.type = option ? option[1] : nil
  end

  def set_item_initial_password_warning(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    initial_password_warning = str(row, 'initial_password_warning')
    option = item.initial_password_warning_options.find { |option| option[0] == initial_password_warning }
    item.initial_password_warning = option ? option[1] : nil
  end

  def set_item_restriction(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    restriction = str(row, 'restriction')
    option = item.restriction_options.find { |option| option[0] == restriction }
    item.restriction = option ? option[1] : nil
  end

  def set_item_lock_state(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    lock_state = str(row, 'lock_state')
    option = item.lock_state_options.find { |option| option[0] == lock_state }
    item.lock_state = option ? option[1] : nil
  end

  def set_item_organization_id(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    organization = str(row, 'organization_id')
    group = nil
    if organization.present?
      group = SS::Group.unscoped.where(name: organization).first
    end

    item.organization_id = group ? group.id : nil
  end

  def set_item_group_ids(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    group_names = str(row, 'group_ids').split("\n")
    groups = SS::Group.unscoped.in(name: group_names)

    item.imported_group_keys = group_names
    item.imported_groups = groups

    item.group_ids = groups.pluck(:id)
  end

  def set_item_webmail_role_ids(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    role_names = str(row, 'webmail_role_ids').split("\n")
    roles = Webmail::Role.in(name: role_names)

    item.imported_webmail_role_keys = role_names
    item.imported_webmail_roles = roles

    item.webmail_role_ids = roles.pluck(:id)
  end

  def set_item_sys_role_ids(row, item, setting)
    account_index = str(row, 'imap_setting.account_index').to_i - 1
    return if account_index != 0

    value = str(row, 'sys_role_ids').to_s
    general_role_ids = Sys::Role.and_general.pluck(:id)

    if value.present?
      add_role_names = value.split(/\n/)
      add_roles = Sys::Role.in(name: add_role_names).to_a
      add_role_ids = add_roles.pluck(:id)

      item.imported_sys_role_keys = add_role_names
      item.imported_sys_roles = add_roles
    else
      add_role_ids = []
    end

    item.sys_role_ids = item.sys_role_ids - general_role_ids + add_role_ids
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

  def purge_webmail_caches
    Webmail::Mail.all.find_each(&:destroy_rfc822)
    Webmail::Mail.all.delete_all
    Webmail::Mailbox.all.delete_all
  end
end
