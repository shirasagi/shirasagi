class Gws::Affair2::TimeCardForms::RegularRecords
  extend SS::Translation
  include ActiveModel::Model
  include SS::PermitParams

  attr_accessor :time_card, :in_file

  permit_params :in_file

  validates :time_card, presence: true
  validates :in_file, presence: true
  validate :validate_in_file, if: ->{ in_file }

  delegate :site, to: :time_card

  def initialize(time_card)
    @time_card = time_card
  end

  def model
    Gws::Affair2::Attendance::Record
  end

  def required_headers
    [
      model.t(:date),
      model.t(:regular_holiday),
      model.t(:regular_start),
      model.t(:regular_close),
      model.t(:regular_break_minutes)
    ]
  end

  def import
    return false if invalid?

    regular_holiday_hash = I18n.t("gws/affair2.options.regular_holiday").map { |k, v| [v, k] }.to_h

    SS::Csv.foreach_row(in_file, headers: true) do |row, idx|
      date = row[model.t(:date)].to_s.strip
      date = Date.parse(date) rescue nil

      record = time_card.records.where(date: date).first
      next if record.nil?

      regular_holiday = row[model.t(:regular_holiday)].to_s.strip
      regular_start = row[model.t(:regular_start)].to_s.strip
      regular_close = row[model.t(:regular_close)].to_s.strip
      regular_break_minutes = row[model.t(:regular_break_minutes)].to_s.strip

      record.regular_holiday = regular_holiday_hash[regular_holiday]
      record.regular_start = parse_time(record.date, regular_start)
      record.regular_close = parse_time(record.date, regular_close)
      record.regular_break_minutes = parse_minutes(regular_break_minutes)
      record.save
    end
    true
  end

  def enum_csv(options)
    drawer = SS::Csv.draw(:export, context: self, model: model) do |drawer|
      drawer.column :date do
        drawer.head { model.t(:date) }
        drawer.body { |item| I18n.l(item.date.to_date, format: :picker) }
      end
      drawer.column :regular_holiday do
        drawer.head { model.t(:regular_holiday) }
        drawer.body { |item| item.label(:regular_holiday) }
      end
      drawer.column :regular_start do
        drawer.head { model.t(:regular_start) }
        drawer.body { |item| format_time(item.date, item.regular_start) }
      end
      drawer.column :regular_close do
        drawer.head { model.t(:regular_close) }
        drawer.body { |item| format_time(item.date, item.regular_close) }
      end
      drawer.column :regular_break_minutes do
        drawer.head { model.t(:regular_break_minutes) }
        drawer.body { |item| item.regular_break_minutes }
      end
    end
    options[:model] = model
    drawer.enum(time_card.records, options)
  end

  def validate_in_file
    if !SS::Csv.valid_csv?(in_file, headers: true, required_headers: required_headers)
      self.errors.add :base, :invalid_csv
    end
  end

  def format_time(date, time)
    return nil if time.blank?

    time = time.in_time_zone
    hour = time.hour
    if date.day != time.day
      hour += 24
    end
    "#{hour}:#{format('%02d', time.min)}"
  end

  def parse_minutes(minutes)
    return nil if minutes.blank?

    minutes = minutes.to_i
    return nil if minutes < 0 || minutes > 240

    minutes
  end

  def parse_time(date, time)
    h, m = time.scan(/^(\d+):(\d+)$/)[0]
    return nil if h.nil? || m.nil?

    h = h.to_i
    m = m.to_i

    start_hour = site.affair2_time_changed_minute / 60
    close_hour = start_hour + 23
    start_minute = 0
    close_minute = 59

    return nil if h < start_hour || h > close_hour
    return nil if m < start_minute || m > close_minute

    date.advance(hours: h).change(min: m, sec: 0)
  end

  class << self
    def t(*args)
      human_attribute_name(*args)
    end
  end
end
