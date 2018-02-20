class Gws::Schedule::PlanCsv::Importer
  include ActiveModel::Model
  include SS::PermitParams
  # import `t` and `tt`
  extend SS::Document::ClassMethods
  extend SS::Translation

  attr_accessor :in_file
  attr_accessor :cur_site
  attr_accessor :cur_user
  attr_reader :imported
  attr_reader :items

  permit_params :in_file

  #validates :in_file, presence: true
  validates :cur_site, presence: true
  validate :validate_import

  def initialize(*args, &block)
    super
    @imported = 0
  end

  def import(opts = {})
    return if invalid?

    @imported = 0
    @items = []

    @table ||= load_csv_table
    @table.each_with_index do |row, i|
      @row_index = i + 2
      @row = row

      item = build_item

      save_item(item, confirm: opts[:confirm])
    end

    errors.empty?
  ensure
    @table = nil
    @row_index = nil
    @row = nil
  end

  private

  def validate_import
    if in_file.blank?
      errors.add(:base, I18n.t('ss.errors.import.blank_file'))
      return
    end

    fname = in_file.original_filename
    if ::File.extname(fname) !~ /^\.csv$/i
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    begin
      @table = load_csv_table
    rescue => e
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
      return
    end

    diff = Gws::Schedule::PlanCsv::Exporter.csv_basic_headers - @table.headers
    if diff.present?
      errors.add(:base, I18n.t('ss.errors.import.invalid_file_type'))
    end
    in_file.rewind
  end

  def load_csv_table
    CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
  end

  def row_value(key)
    v = @row[Gws::Schedule::Plan.t(key)].presence
    return v if v.blank?
    v.strip.presence
  end

  def build_item
    id = row_value('id')

    item = nil
    item = Gws::Schedule::Plan.unscoped.where(id: id).first if id.present?
    item ||= Gws::Schedule::Plan.new

    item.cur_site = cur_site
    item.cur_user = cur_user

    %w(
      state name start_on end_on start_at end_at allday
      category_id priority color text_type text
      attendance_check_state
      main_facility_id
      readable_setting_range
      permission_level
    ).each do |k|
      item[k] = row_value(k)
    end

    %w(
      member_ids member_custom_group_ids
      facility_ids facility_column_values
      readable_member_ids readable_group_ids readable_custom_group_ids
      custom_group_ids group_ids user_ids
    ).each do |k|
      item[k] = JSON.parse(row_value(k))
    end

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

    if !opts[:confirm] && result == 'entry'
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

  def set_errors(item)
    item.errors.full_messages.each do |error|
      errors.add(:base, "#{@row_index}: #{error}")
    end
  end
end
