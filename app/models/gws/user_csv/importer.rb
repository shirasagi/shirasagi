class Gws::UserCsv::Importer
  include ActiveModel::Model

  attr_accessor :in_file
  attr_accessor :cur_site
  attr_accessor :imported

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
    row[Gws::User.t(key)].to_s.strip
  end

  def build_item
    id = row_value('id')
    # email = row_value('email')
    # uid = row_value('uid')

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

    # password
    password = row_value('password')
    item.in_password = password if password.present?

    # title
    value = row_value("title_ids")
    title = Gws::UserTitle.site(site).where(name: value).first
    item.in_title_id = title ? title.id : ''

    # type
    value = row[t("type")].to_s.strip
    type = item.type_options.find { |v, k| v == value }
    item.type = type[1] if type

    # initial_password_warning
    initial_password_warning = row[t("initial_password_warning")].to_s.strip
    if initial_password_warning == I18n.t('ss.options.state.enabled')
      item.initial_password_warning = 1
    else
      item.initial_password_warning = nil
    end

    # organization_id
    value = row[t("organization_id")].to_s.strip
    group = SS::Group.where(name: value).first
    item.organization_id = group ? group.id : nil

    # groups
    groups = row[t("groups")].to_s.strip.split(/\n/)
    item.group_ids = SS::Group.in(name: groups).map(&:id)

    # main_group_ids
    value = row[t("gws_main_group_ids")].to_s.strip
    group = SS::Group.where(name: value).first
    item.in_gws_main_group_id = group ? group.id : ''

    # switch_user_id
    value = row[t("switch_user_id")].to_s.strip.split(',', 2)
    user = SS::User.where(id: value[0], name: value[1]).first
    item.switch_user_id = user ? user.id : nil

    # gws_roles
    gws_roles = row[t("gws_roles")].to_s.strip.split(/\n/)
    add_gws_roles(item, gws_roles)

    item
  end

  def add_gws_roles(item, gws_roles)
    site_role_ids = Gws::Role.site(@cur_site).map(&:id)
    add_role_ids = Gws::Role.site(@cur_site).in(name: gws_roles).map(&:id)
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
