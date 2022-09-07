class Gws::Schedule::PlanCsv::Importer
  include ActiveModel::Model
  include SS::PermitParams
  # import `t` and `tt`
  extend SS::Document::ClassMethods
  extend SS::Translation
  include Cms::CsvImportBase

  attr_accessor :in_file, :cur_site, :cur_user
  attr_reader :imported, :items

  permit_params :in_file

  validates :cur_site, presence: true
  validate :validate_import

  class << self
    def required_headers
      I18n.with_locale(I18n.default_locale) do
        %w(id name start_at end_at).map do |k|
          Gws::Schedule::Plan.t(k)
        end
      end
    end
  end

  def initialize(*args, &block)
    super
    @imported = 0
  end

  def import(opts = {})
    return if invalid?

    @imported = 0
    @items = []
    @row_index = 1
    create_importer
    self.class.each_csv(in_file) do |row|
      @row_index += 1
      @row = row
      item = build_item
      save_item(item, confirm: opts[:confirm])
    end
    errors.empty?
  ensure
    @row_index = nil
    @row = nil
  end

  private

  def validate_import
    if in_file.blank?
      errors.add(:base, I18n.t('ss.errors.import.blank_file'))
      return
    end

    if ::File.extname(in_file.original_filename).casecmp(".csv") != 0
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    unless self.class.valid_csv?(in_file, max_read_lines: 1)
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    true
  end

  def create_importer
    @importer ||= begin
      drawer = SS::Csv.draw(:import, context: self, model: Gws::Schedule::Plan) do |drawer|
        define_importer_basic(drawer)
        # define_importer_reminder(drawer)
        # define_importer_schedule_repeat(drawer)
        define_importer_notify_setting(drawer)
        define_importer_markdown(drawer)
        # define_importer_file(drawer)
        define_importer_schedule_reports(drawer)
        define_importer_member(drawer)
        define_importer_schedule_attendance(drawer)
        define_importer_schedule_facility(drawer)
        define_importer_schedule_facility_column_values(drawer)
        define_importer_schedule_approval(drawer)
        define_importer_readable_setting(drawer)
        define_importer_group_permission(drawer)
      end
      drawer.create(fields: { form: "main_facility", column_values: "facility_column_values" })
    end
  end

  def define_importer_basic(drawer)
    drawer.simple_column :name
    drawer.label_column :allday
    drawer.simple_column :start_at do |row, item, head, value|
      if item.allday?
        item.start_on = value
      else
        item.start_at = value
      end
    end
    drawer.simple_column :end_at do |row, item, head, value|
      if item.allday?
        item.end_on = value
      else
        item.end_at = value
      end
    end
    drawer.simple_column :category_id do |row, item, head, value|
      site = cur_site
      user = cur_user
      item.category = value.try do
        criteria = Gws::Schedule::Category.all
        criteria = criteria.site(site)
        criteria = criteria.readable(user, site: site)
        criteria = criteria.where(name: value)

        criteria.reorder(order: 1, name: 1).first
      end
    end
    drawer.label_column :priority
    drawer.simple_column :color
  end

  def define_importer_notify_setting(drawer)
    drawer.label_column :notify_state
  end

  def define_importer_markdown(drawer)
    drawer.label_column :text_type
    drawer.simple_column :text
  end

  def define_importer_schedule_reports(drawer)
  end

  def define_importer_member(drawer)
    drawer.simple_column :member_custom_group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_custom_groups.where("$and" => [{ name: { "$in" => names } }])
      item.member_custom_group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :member_group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_groups.where("$and" => [{ name: { "$in" => names } }])
      item.member_group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :member_ids do |row, item, head, value|
      uid_or_emails = to_array(value)

      conds = []
      conds << { uid: { "$in" => uid_or_emails } }
      conds << { email: { "$in" => uid_or_emails } }
      criteria = readable_users.where("$and" => [{ "$or" => conds }])

      item.member_ids = criteria.pluck(:id)
    end
  end

  def define_importer_schedule_attendance(drawer)
    drawer.label_column :attendance_check_state
  end

  def define_importer_schedule_facility(drawer)
    drawer.simple_column :facility_ids do |row, item, head, value|
      names = to_array(value)
      item.facility_ids = readable_facilities.where("$and" => [{ name: { "$in" => names } }]).pluck(:id)
    end
    drawer.simple_column :main_facility_id do |row, item, head, value|
      all_facilities = readable_facilities
      item.main_facility = value.try { all_facilities.where(name: value).reorder(order: 1, name: 1).first }
    end
  end

  def define_importer_schedule_facility_column_values(drawer)
    readable_facilities.reorder(order: 1, name: 1).each do |facility|
      drawer.form facility.name do
        facility.columns.each do |column|
          drawer.column column.name do |row, item, _facility, _column, values|
            import_column(row, item, facility, column, values)
          end
        end
      end
    end
  end

  def import_column(_row, item, _facility, column, values)
    column_value = item.facility_column_values.where(column_id: column.id).first
    if column_value.blank?
      column_value = item.facility_column_values.build(
        _type: column.value_type.name, column: column, name: column.name, order: column.order
      )
    end
    column_value.import_csv(values)
    column_value
  end

  def define_importer_schedule_approval(drawer)
    drawer.simple_column :approval_member_ids do |row, item, head, value|
      uid_or_emails = to_array(value)

      conds = []
      conds << { uid: { "$in" => uid_or_emails } }
      conds << { email: { "$in" => uid_or_emails } }
      criteria = readable_users.where("$and" => [{ "$or" => conds }])

      item.approval_member_ids = criteria.pluck(:id)
    end
  end

  def define_importer_readable_setting(drawer)
    drawer.label_column :readable_setting_range
    drawer.simple_column :readable_custom_group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_custom_groups.where("$and" => [{ name: { "$in" => names } }])
      item.readable_custom_group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :readable_group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_groups.where("$and" => [{ name: { "$in" => names } }])
      item.readable_group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :readable_member_ids do |row, item, head, value|
      uid_or_emails = to_array(value)

      conds = []
      conds << { uid: { "$in" => uid_or_emails } }
      conds << { email: { "$in" => uid_or_emails } }
      criteria = readable_users.where("$and" => [{ "$or" => conds }])

      item.readable_member_ids = criteria.pluck(:id)
    end
  end

  def define_importer_group_permission(drawer)
    drawer.simple_column :custom_group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_custom_groups.where("$and" => [{ name: { "$in" => names } }])
      item.custom_group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :group_ids do |row, item, head, value|
      names = to_array(value)
      criteria = readable_groups.where("$and" => [{ name: { "$in" => names } }])
      item.group_ids = criteria.pluck(:id)
    end
    drawer.simple_column :user_ids do |row, item, head, value|
      uid_or_emails = to_array(value)

      conds = []
      conds << { uid: { "$in" => uid_or_emails } }
      conds << { email: { "$in" => uid_or_emails } }
      criteria = readable_users.where("$and" => [{ "$or" => conds }])

      item.user_ids = criteria.pluck(:id)
    end
    drawer.simple_column :permission_level
  end

  def readable_facilities
    @readable_facilities ||= begin
      criteria = Gws::Facility::Item.site(cur_site)
      criteria = criteria.active
      criteria = criteria.readable(cur_user, site: cur_site)
      criteria
    end
  end

  def readable_custom_groups
    @readable_custom_groups ||= begin
      criteria = Gws::CustomGroup.all
      criteria = criteria.site(cur_site)
      criteria = criteria.readable(cur_user, site: cur_site)
      criteria
    end
  end

  def readable_groups
    @readable_groups ||= begin
      criteria = Gws::Group.all
      criteria = criteria.site(cur_site)
      criteria
    end
  end

  def readable_users
    @readable_users ||= begin
      criteria = Gws::User.all
      criteria = criteria.site(cur_site)
      criteria = criteria.active
      criteria = criteria.readable_users(cur_user, site: cur_site)
      criteria
    end
  end

  delegate :to_array, to: SS::Csv::CsvImporter

  def row_value(key)
    v = @row[Gws::Schedule::Plan.t(key)].presence
    return v if v.blank?

    v.strip.presence
  end

  def build_item
    id = row_value('id')
    item = Gws::Schedule::Plan.unscoped.site(cur_site).where(id: id).first if id.present?
    item ||= Gws::Schedule::Plan.new
    item.cur_site = cur_site
    item.cur_user = cur_user

    @importer.import_row(@row, item)

    item
  end

  def save_item(item, opts)
    if item.persisted?
      result   = 'exist'
      messages = [I18n.t('gws/schedule.import.exist')]
    elsif !item.allowed?(:edit, cur_user, site: cur_site)
      result   = 'error'
      messages = [I18n.t('errors.messages.auth_error')]
    elsif !item.valid?
      result   = 'error'
      messages = item.errors.full_messages
    else
      result   = 'entry'
      messages = [I18n.t('gws/schedule.import.entry')]
    end

    if !opts[:confirm] && %w(entry exist).include?(result)
      if item.save
        @imported += 1
        result   = 'saved'
        messages = [I18n.t('gws/schedule.import.saved')]
      else
        result   = 'error'
        messages = item.errors.full_messages
      end
    end

    @items << {
      id: item.id.to_s,
      start_at: item.start_at,
      end_at: item.end_at,
      name: item.name,
      allday: item.allday,
      result: result,
      messages: messages
    }
  end
end
