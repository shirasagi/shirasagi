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

    create_importer
    Rails.logger.tagged(::File.basename(in_file.original_filename)) do
      SS::Csv.foreach_row(in_file, headers: true) do |row, i|
        @row_index = i + 2
        @row = row

        item = build_item
        next if item.blank?

        save_item(item)
        save_form_data(item)
      end
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

    extname = ::File.extname(in_file.original_filename)
    if extname.blank? || extname.casecmp('.csv') != 0
      errors.add(:in_file, :invalid_file_type)
      return
    end

    required_headers = %i[id name uid email groups].map { |key| Gws::User.t(key) }
    unless SS::Csv.valid_csv?(in_file, headers: true, required_headers: required_headers)
      errors.add :in_file, :invalid_file_type
      return
    end
  ensure
    in_file.rewind
  end

  def row_value(key)
    v = @row[Gws::User.t(key)].presence
    return v if v.blank?
    v.strip.presence
  end

  def build_item
    item, fatal_error = find_item
    return if fatal_error
    item ||= Gws::User.new
    item.cur_site = cur_site
    item.cur_user = cur_user

    @importer.import_row(@row, item)

    item
  end

  def find_item
    id = row_value(:id)
    if id.present?
      item = Gws::User.unscoped.site(cur_site).where(id: id).first
      if item.blank?
        errors.add(:base, :not_found, line_no: @row_index, id: id)
        return [ nil, true ]
      end

      return [ item, false ]
    end

    %i[uid email].each do |key|
      val = row_value(key)
      next if val.blank?

      item = Gws::User.unscoped.site(cur_site).where(key => val).first
      next if item.blank?

      return [ item, false ]
    end

    [ nil, false ]
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

  def site_group_ids
    @site_group_ids ||= Gws::Group.site(cur_site.root).pluck(:id)
  end

  def site_user_ids
    @site_user_ids ||= Gws::User.site(cur_site).pluck(:id)
  end

  def site_role_ids
    @site_role_ids ||= Gws::Role.site(cur_site).pluck(:id)
  end

  def general_role_ids
    @general_role_ids ||= Sys::Role.and_general.pluck(:id)
  end

  def site_form
    return @site_form if instance_variable_defined?(:@site_form)
    @site_form ||= Gws::UserForm.find_for_site(cur_site)
  end

  delegate :to_array, :from_label, to: SS::Csv::CsvImporter

  def create_importer
    @importer ||= SS::Csv.draw(:import, context: self, model: Gws::User) do |importer|
      define_importer_required(importer)
      define_importer_basic1(importer)
      define_importer_basic2(importer)
      define_importer_basic3(importer)
      define_importer_locale_setting(importer)
      define_importer_ldap(importer)
      define_importer_public_duty(importer)
      define_importer_affair(importer)
      define_importer_gws_role(importer)
      define_importer_sys_role(importer)
      define_importer_webmail_role(importer)
      define_importer_readable(importer)
    end.create
  end

  def define_importer_required(importer)
    importer.simple_column :name
    importer.simple_column :uid
    importer.simple_column :email
    importer.simple_column :password do |row, item, head, value|
      item.in_password = value if value.present?
    end
    importer.simple_column :groups do |row, item, head, value|
      item.group_ids = item.group_ids - site_group_ids
      if value.present?
        item.group_ids += Gws::Group.site(cur_site).in(name: value.split(/\n/)).pluck(:id)
      end

      item.imported_group_keys = value.to_s.split(/\n/)
      item.imported_groups = item.groups
      item.imported_gws_group = cur_site
      item.group_ids = item.group_ids.uniq.sort
    end
  end

  def define_importer_basic1(importer)
    importer.simple_column :kana
    importer.simple_column :organization_uid
    importer.simple_column :organization_id do |row, item, head, value|
      group = Gws::Group.site(cur_site).where(name: value).first if value.present?
      item.organization_id = group ? group.id : nil
    end
    importer.simple_column :tel
    importer.simple_column :tel_ext
    importer.simple_column :title_ids do |row, item, head, value|
      if value.present?
        title = Gws::UserTitle.site(cur_site).where(code: value).first

        item.imported_gws_user_title_key = value
        item.imported_gws_user_title = title
      end

      item.in_title_id = title ? title.id : ''
    end
    importer.simple_column :occupation_ids do |row, item, head, value|
      if value.present?
        occupation = Gws::UserOccupation.site(cur_site).where(code: value).first

        item.imported_gws_user_occupation_key = value
        item.imported_gws_user_occupation = occupation
      end

      item.in_occupation_id = occupation ? occupation.id : ''
    end
    importer.simple_column :type do |row, item, head, value|
      item.type = from_label(value, item.type_options).presence
    end
  end

  def define_importer_basic2(importer)
    importer.simple_column :account_start_date
    importer.simple_column :account_expiration_date
    importer.simple_column :initial_password_warning do |row, item, head, value|
      if value == I18n.t('ss.options.state.enabled')
        item.initial_password_warning = 1
      else
        item.initial_password_warning = nil
      end
    end
    importer.simple_column :session_lifetime
    importer.simple_column :restriction do |row, item, head, value|
      item.restriction = from_label(value, item.restriction_options).presence
    end
    importer.simple_column :lock_state do |row, item, head, value|
      item.lock_state = from_label(value, item.lock_state_options).presence
    end
    importer.simple_column :deletion_lock_state do |row, item, head, value|
      item.deletion_lock_state = from_label(value, item.deletion_lock_state_options).presence
    end
  end

  def define_importer_basic3(importer)
    importer.simple_column :gws_main_group_ids do |row, item, head, value|
      if value.present?
        group = Gws::Group.site(cur_site).and(name: value).first
        item.imported_gws_main_group_key = value
        item.imported_gws_main_group = group
      end

      item.in_gws_main_group_id = group ? group.id : ''
    end
    importer.simple_column :gws_default_group_ids do |row, item, head, value|
      if value.present?
        group = Gws::Group.site(cur_site).and(name: value).first
        # item.imported_gws_default_group_key = value
        # item.imported_gws_default_group = group
      end

      item.in_gws_default_group_id = group ? group.id : ''
    end
    importer.simple_column :switch_user_id do |row, item, head, value|
      if value.present?
        value = value.split(',', 2)
        user = Gws::User.site(cur_site).where(id: value[0], name: value[1]).first
      end
      item.switch_user_id = user ? user.id : nil
    end
    importer.simple_column :remark
  end

  def define_importer_locale_setting(importer)
    importer.simple_column :lang do |row, item, head, value|
      item.lang = from_label(value, item.lang_options).presence
    end
    importer.simple_column :timezone do |row, item, head, value|
      item.timezone = from_label(value, item.timezone_options).presence
    end
  end

  def define_importer_ldap(importer)
    importer.simple_column :ldap_dn
  end

  def define_importer_public_duty(importer)
    importer.simple_column :charge_name
    importer.simple_column :charge_address
    importer.simple_column :charge_tel
    importer.simple_column :divide_duties
  end

  def define_importer_affair(importer)
    importer.simple_column :staff_category do |row, item, head, value|
      item.staff_category = from_label(value, item.staff_category_options).presence
    end
    importer.simple_column :staff_address_uid
    importer.simple_column :gws_superior_group_ids do |row, item, head, value|
      item.in_gws_superior_group_ids = Gws::Group.site(cur_site).in(name: to_array(value)).pluck(:id)
    end
    importer.simple_column :gws_superior_user_ids do |row, item, head, value|
      if value.present?
        user_ids = to_array(value).map { |term| term.split(",", 2).first.strip }
        user_ids.select!(&:numeric?)
        user_ids.map!(&:to_i)
        users = Gws::User.site(cur_site).in(id: user_ids)
      else
        users = Gws::User.none
      end

      item.in_gws_superior_user_ids = users.pluck(:id)
    end
  end

  def define_importer_gws_role(importer)
    importer.simple_column :gws_roles do |row, item, head, value|
      if value.present?
        add_role_names = to_array(value)
        add_roles = Gws::Role.site(cur_site).in(name: add_role_names)
        add_role_ids = add_roles.pluck(:id)

        item.imported_gws_role_keys = add_role_names
        item.imported_gws_roles = add_roles
      else
        add_role_ids = []
      end

      item.gws_role_ids = item.gws_role_ids - site_role_ids + add_role_ids
    end
  end

  def define_importer_sys_role(importer)
    importer.simple_column :sys_roles do |row, item, head, value|
      if value.present?
        add_role_names = value.split(/\n/)
        add_roles = Sys::Role.all.and_general.in(name: add_role_names).to_a
        add_role_ids = add_roles.pluck(:id)

        item.imported_sys_role_keys = add_role_names
        item.imported_sys_roles = add_roles
      else
        add_role_ids = []
      end

      item.sys_role_ids = item.sys_role_ids - general_role_ids + add_role_ids
    end
  end

  def define_importer_webmail_role(importer)
    importer.simple_column :webmail_roles do |row, item, head, value|
      if value.present?
        add_role_names = value.split(/\n/)
        add_roles = Webmail::Role.in(name: add_role_names)
        add_role_ids = add_roles.pluck(:id)

        item.imported_webmail_role_keys = add_role_names
        item.imported_webmail_roles = add_roles
      else
        add_role_ids = []
      end

      item.webmail_role_ids = add_role_ids
    end
  end

  def define_importer_readable(importer)
    importer.simple_column :readable_setting_range do |row, item, head, value|
      item.readable_setting_range = from_label(value, item.readable_setting_range_options)
    end
    importer.simple_column :readable_group_ids do |row, item, head, value|
      if value.present?
        groups = Gws::Group.site(cur_site).in(name: to_array(value))
      else
        groups = Gws::Group.none
      end
      item.readable_group_ids = item.readable_group_ids - site_group_ids + groups.pluck(:id)
    end
    importer.simple_column :readable_member_ids do |row, item, head, value|
      if value.present?
        user_ids = to_array(value).map { |term| term.split(",", 2).first }
        user_ids.select!(&:numeric?)
        user_ids.map!(&:to_i)

        users = Gws::User.site(cur_site).in(id: user_ids)
      else
        users = Gws::User.none
      end
      item.readable_member_ids = item.readable_member_ids - site_user_ids + users.pluck(:id)
    end
  end
end
