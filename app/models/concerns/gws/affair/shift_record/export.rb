module Gws::Affair::ShiftRecord::Export
  extend ActiveSupport::Concern

  included do
    attr_accessor :in_file
    permit_params :in_file
  end

  def each_csv(&block)
    csv = ::CSV.read(in_file.path, headers: true, encoding: 'SJIS:UTF-8')
    csv.each(&block)
  end

  def import_csv
    validate_import_file
    return false unless errors.empty?

    each_csv do |row|
      item = self.class.initialize_record(shift_calendar, row)
      if item.same_default?
        item.destroy if item.persisted?
      else
        item.save!
      end
    end

    errors.empty?
  end

  def same_default?
    duty_hour = shift_calendar.default_duty_hour
    holiday_calendar = shift_calendar.default_holiday_calendar

    default_start_at_hour = duty_hour.affair_start(date).hour
    default_start_at_minute = duty_hour.affair_start(date).min
    default_end_at_hour = duty_hour.affair_end(date).hour
    default_end_at_minute = duty_hour.affair_end(date).min
    default_wday_type = holiday_calendar.leave_day?(date) ? "holiday" : "workday"

    return false if self.affair_start_at_hour != default_start_at_hour
    return false if self.affair_start_at_minute != default_start_at_minute
    return false if self.affair_end_at_hour != default_end_at_hour
    return false if self.affair_end_at_minute != default_end_at_minute
    return false if self.wday_type != default_wday_type
    true
  end

  def validate_import_file
    return errors.add :in_file, :blank if in_file.blank?

    fname = in_file.original_filename
    unless /^\.csv$/i.match?(::File.extname(fname))
      errors.add :in_file, :invalid_file_type
      return
    end

    begin
      no = 0
      each_csv do |row|
        no += 1
        item = self.class.initialize_record(shift_calendar, row)
        item.errors.full_messages.each do |e|
          errors.add :base, "##{no}:#{e}"
        end
      end
      in_file.rewind
    rescue => e
      errors.add :in_file, :invalid_file_type
    end
  end

  module ClassMethods
    def initialize_record(shift_calendar, row)
      date = row[self.t(:date)].to_s.strip
      start_at = row[self.t(:start_at)].to_s.strip
      end_at = row[self.t(:end_at)].to_s.strip
      wday_type = row[self.t(:wday_type)].to_s.strip

      date = Time.zone.parse(date).try(:to_datetime)
      start_at = Time.zone.parse(start_at).try(:to_datetime)
      end_at = Time.zone.parse(end_at).try(:to_datetime)

      item = self.find_or_initialize_by(shift_calendar_id: shift_calendar.id, date: date)
      item.reload if item.persisted?

      item.errors.add :date, :invalid if date.nil?
      item.errors.add :start_at, :invalid if start_at.nil?
      item.errors.add :end_at, :invalid if end_at.nil?
      if start_at >= end_at
        item.errors.add :end_at, :greater_than, count: item.t(:start_at)
      end

      return item if item.errors.present?

      item.affair_start_at_hour = start_at.hour
      item.affair_start_at_minute = start_at.min
      item.affair_end_at_hour = end_at.hour
      item.affair_end_at_minute = end_at.min

      if wday_type == I18n.t("gws/affair.options.wday_type.holiday")
        item.wday_type = "holiday"
      elsif wday_type == I18n.t("gws/affair.options.wday_type.workday")
        item.wday_type = "workday"
      end

      item.valid?
      return item if item.errors.present?

      item
    end

    def encode_sjis(str)
      str.encode("SJIS", invalid: :replace, undef: :replace)
    end

    def csv_headers
      %w(date wday start_at end_at wday_type).map { |k| self.t(k) }
    end

    def enum_csv(shift_calendar, year)
      d1 = Time.zone.parse("#{year}/4/1")
      d2 = d1.advance(years: 1, days: -1)

      d1 = d1.to_date
      d2 = d2.to_date

      Enumerator.new do |y|
        y << encode_sjis(csv_headers.to_csv)

        (d1..d2).each do |d|
          d = d.to_datetime

          line = []
          line << d.strftime("%Y/%m/%d")
          line << I18n.l(d, format: "%a")
          line << shift_calendar.affair_start(d).strftime("%H:%M")
          line << shift_calendar.affair_end(d).strftime("%H:%M")

          if shift_calendar.leave_day?(d)
            line << I18n.t("gws/affair.options.wday_type.holiday")
          else
            line << I18n.t("gws/affair.options.wday_type.workday")
          end

          y << encode_sjis(line.to_csv)
        end
      end
    end
  end
end
