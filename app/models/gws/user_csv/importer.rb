class Gws::UserCsv::Importer
  include ActiveModel::Model
  include SS::PermitParams
  # import `t` and `tt`
  extend SS::Document::ClassMethods

  attr_accessor :in_file, :cur_site, :cur_user, :webmail_support
  attr_reader :imported

  permit_params :in_file, :webmail_support

  validates :in_file, presence: true
  validates :cur_site, presence: true
  validate do
    I18n.with_locale(I18n.default_locale) { validate_import }
  end

  def initialize(*args, &block)
    super
    @imported = 0
  end

  def import
    I18n.with_locale(I18n.default_locale) { _import }
  end

  private

  def _import
    return if invalid?

    @imported = 0

    SS::Csv.foreach_row(in_file, headers: true) do |row, i|
      @row_index = i + 2
      @row = row

      item = build_item
      next if item.blank?

      save_item(item)
      save_form_data(item)
    end

    errors.empty?
  ensure
    @table = nil
    @row_index = nil
    @row = nil
  end

  def validate_import
    if in_file.blank?
      errors.add(:in_file, :blank)
      return
    end

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add(:in_file, :invalid_file_type)
      return
    end

    begin
      SS::Csv.foreach_row(in_file, headers: true) do |row|
        diff = Gws::UserCsv::Exporter.csv_basic_headers(webmail_support: @webmail_support) - row.headers
        if diff.present?
          errors.add :in_file, :invalid_file_type
        end
        break
      end
    rescue => e
      errors.add(:in_file, :invalid_file_type)
      return
    end

    in_file.rewind
  end

  def row_value(key)
    v = @row[Gws::User.t(key)].presence
    return v if v.blank?
    v.strip.presence
  end

  def label_value(key)
    v = @row[Gws::User.t(key)].presence
    label_h = Gws::User.new.send("#{key}_options").to_h
    label_h[v]
  end

  def build_item
    item, fatal_error = find_item
    return if fatal_error
    item ||= Gws::User.new
    item.cur_site = cur_site
    item.cur_user = cur_user

    %w(
      name kana uid organization_uid email tel tel_ext
      account_start_date account_expiration_date session_lifetime remark ldap_dn
    ).each do |k|
      item[k] = row_value(k)
    end

    item["staff_category"] = label_value("staff_category")
    item["staff_address_uid"] = row_value("staff_address_uid")

    keys = %i[
      set_password set_title set_occupation set_type set_initial_password_warning set_organization_id set_group_ids
      set_main_group_ids set_switch_user_id set_gws_roles set_sys_roles
    ]
    keys += %i[set_webmail_roles] if webmail_support

    keys.each do |m|
      send(m, item)
    end

    item
  end

  def find_item
    id = row_value('id')
    if id.present?
      item = Gws::User.unscoped.site(cur_site).where(id: id).first
      if item.blank?
        errors.add(:base, :not_found, line_no: @row_index, id: id)
        return [ nil, true ]
      end

      return [ item, false ]
    end

    %w(uid email).each do |key|
      val = row_value(key)
      next if val.blank?

      item = Gws::User.unscoped.site(cur_site).where(key => val).first
      next if item.blank?

      return [ item, false ]
    end

    [ nil, false ]
  end

  def set_password(item)
    password = row_value('password')
    item.in_password = password if password.present?
  end

  def set_title(item)
    value = row_value('title_ids')

    if value.present?
      title = Gws::UserTitle.site(cur_site).where(code: value).first

      item.imported_gws_user_title_key = value
      item.imported_gws_user_title = title
    end

    item.in_title_id = title ? title.id : ''
  end

  def set_occupation(item)
    value = row_value('occupation_ids')

    if value.present?
      occupation = Gws::UserOccupation.site(cur_site).where(code: value).first

      item.imported_gws_user_occupation_key = value
      item.imported_gws_user_occupation = occupation
    end

    item.in_occupation_id = occupation ? occupation.id : ''
  end

  def set_type(item)
    value = row_value('type')
    type = item.type_options.find { |v, k| v == value } if value.present?
    item.type = type ? type[1] : ''
  end

  def set_initial_password_warning(item)
    initial_password_warning = row_value('initial_password_warning')
    if initial_password_warning == I18n.t('ss.options.state.enabled')
      item.initial_password_warning = 1
    else
      item.initial_password_warning = nil
    end
  end

  def set_organization_id(item)
    value = row_value('organization_id')
    group = SS::Group.where(name: value).first if value.present?
    item.organization_id = group ? group.id : nil
  end

  def set_group_ids(item)
    item.group_ids = item.group_ids - rm_group_ids
    value = row_value('groups')
    if value.present?
      item.group_ids += SS::Group.in(name: value.split(/\n/)).pluck(:id)
    end

    item.imported_group_keys = value.to_s.split(/\n/)
    item.imported_groups = item.groups
    item.imported_gws_group = cur_site
    item.group_ids = item.group_ids.uniq.sort
  end

  def set_main_group_ids(item)
    value = row_value('gws_main_group_ids')

    if value.present?
      group = SS::Group.in_group(cur_site).and(name: value).first
      item.imported_gws_main_group_key = value
      item.imported_gws_main_group = group
    end

    item.in_gws_main_group_id = group ? group.id : ''
  end

  def set_switch_user_id(item)
    value = row_value('switch_user_id')
    if value.present?
      value = value.split(',', 2)
      user = SS::User.where(id: value[0], name: value[1]).first
    end
    item.switch_user_id = user ? user.id : nil
  end

  def set_gws_roles(item)
    value = row_value('gws_roles')
    if value.present?
      add_role_names = value.split(/\n/)
      add_roles = Gws::Role.site(cur_site).in(name: add_role_names).to_a
      add_role_ids = add_roles.pluck(:id)

      item.imported_gws_role_keys = add_role_names
      item.imported_gws_roles = add_roles
    else
      add_role_ids = []
    end
    site_role_ids = Gws::Role.site(cur_site).pluck(:id)
    item.gws_role_ids = item.gws_role_ids - site_role_ids + add_role_ids
  end

  def set_webmail_roles(item)
    value = row_value('webmail_roles').to_s
    if value.present?
      add_role_names = value.split(/\n/)
      add_roles = Webmail::Role.in(name: add_role_names).to_a
      add_role_ids = add_roles.pluck(:id)

      item.imported_webmail_role_keys = add_role_names
      item.imported_webmail_roles = add_roles
    else
      add_role_ids = []
    end
    item.webmail_role_ids = add_role_ids
  end

  def set_sys_roles(item)
    value = row_value('sys_roles').to_s
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

  def save_item(item)
    if item.save
      @imported += 1
    else
      set_errors(item)
    end
  end

  def set_errors(item)
    sig = "#{Gws::User.t(:uid)}: #{item.uid}の" if item.uid.present?
    sig ||= "#{Gws::User.t(:email)}: #{item.email}の" if item.email.present?
    sig ||= "#{Gws::User.t(:id)}: #{item.id}の" if item.persisted?
    SS::Model.copy_errors(item, self, prefix: "#{@row_index}行目: #{sig}")
  end

  def save_form_data(item)
    return if item.new_record?

    @form ||= Gws::UserForm.find_for_site(cur_site)
    return if @form.blank?
    return if @form.state_closed?

    form_data = Gws::UserFormData.site(cur_site).user(item).form(@form).order_by(id: 1, created: 1).first_or_create
    form_data.cur_site = cur_site
    form_data.cur_form = @form
    form_data.cur_user = item

    new_column_values = @form.columns.map do |column|
      value = @row["#{Gws::UserCsv::Exporter::PREFIX}#{column.name}"].presence
      column.serialize_value(value)
    end

    form_data.update_column_values(new_column_values)
    form_data.save
  end

  def rm_group_ids
    @rm_group_ids ||= SS::Group.where(name: /\A#{Regexp.escape(cur_site.root.name)}/).pluck(:id)
  end
end
