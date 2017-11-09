class Gws::UserCsv::Importer
  include ActiveModel::Model

  attr_accessor :in_file
  attr_accessor :cur_site
  attr_accessor :imported

  validates :in_file, presence: true
  validates :cur_site, presence: true
  validate :validate_import

  def import
    return if invalid?

    @imported = 0

    @table ||= load_csv_table
    @table.each_with_index do |row, i|
      @row_index = i + 2
      @row = row

      item = build_item

      save_item(item)
    end

    errors.empty?
  end

  private

  def validate_import
    if in_file.blank?
      errors.add(:in_file, :blank)
      return
    end

    fname = in_file.original_filename
    if ::File.extname(fname) !~ /^\.csv$/i
      errors.add(:in_file, :invalid_file_type)
      return
    end

    begin
      @table = load_csv_table
    rescue => e
      errors.add(:in_file, :invalid_file_type)
      return
    end

    if @table.headers != self.class.csv_headers.map { |k| t(k) }
      errors.add :in_file, :invalid_file_type
    end
    in_file.rewind
  end

  def load_csv_table
    CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
  end

  def row_value(key)
    v = row[Gws::User.t(key)].presence
    return v if v.blank?
    v.strip.presence
  end

  def build_item
    id = row_value('id')
    if id.present?
      item = Gws::User.unscoped.where(id: id).first
      if item.blank?
        errors.add(:base, :not_found, line_no: @row_index, id: id)
        return nil
      end
    else
      item = Gws::User.new
    end
    item.cur_site = cur_site

    %w(
      name kana uid organization_uid email tel tel_ext
      account_start_date account_expiration_date session_lifetime remark ldap_dn
    ).each do |k|
      item[k] = row_value(k)
    end

    %i[
      set_password set_title set_type set_initial_password_warning set_organization_id set_group_ids
      set_main_group_ids set_switch_user_id set_gws_roles
    ].each do |m|
      send(m, item)
    end

    item
  end

  def set_password(item)
    password = row_value('password')
    item.in_password = password if password.present?
  end

  def set_title(item)
    value = row_value('title_ids')
    title = Gws::UserTitle.site(cur_site).where(name: value).first if value.present?
    item.in_title_id = title ? title.id : ''
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
    value = row_value('groups')
    if value.present?
      groups = SS::Group.in(name: value.split(/\n/))
    else
      groups = SS::Group.none
    end
    item.group_ids = groups.pluck(:id)
  end

  def set_main_group_ids(item)
    value = row_value('gws_main_group_ids')
    group = SS::Group.where(name: value).first if value.present?
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
      add_role_ids = Gws::Role.site(cur_site).in(name: value.split(/\n/)).pluck(:id)
    else
      add_role_ids = []
    end
    site_role_ids = Gws::Role.site(cur_site).pluck(:id)
    item.gws_role_ids = item.gws_role_ids - site_role_ids + add_role_ids
  end

  def save_item(item)
    if item.save
      @imported += 1
    else
      set_errors(item)
    end
  end

  def set_errors(item)
    item.errors.full_messages.each do |error|
      errors.add(:base, "#{@row_index}: #{error}")
    end
  end
end
