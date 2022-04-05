class Event::Extensions::Recurrence
  include ActiveModel::Model
  include ActiveModel::Attributes
  include SS::Liquidization

  TERM_LIMIT = 1.year

  # 種類; start_at / end_at のデータ型を示す
  attribute :kind, :string, default: ->{ "date" }
  # 開始日/開始日時（inclusive）
  attribute :start_at, :datetime
  # 終了日/終了日時（inclusive）
  attribute :end_at, :datetime
  # 繰り返し頻度; daily か weekly
  attribute :frequency, :string
  # 繰り返し期限（inclusive）
  attribute :until_on, :date
  # attribute :interval, :integer
  # attribute :count, :integer
  # frequency が weekly の場合の曜日
  attribute :by_days
  # 除外日
  attribute :exclude_dates

  attr_accessor :in_update_from_view, :in_start_time, :in_end_time, :in_exclude_dates

  validates :kind, presence: true, inclusion: { in: %w(date datetime), allow_blank: true }
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :frequency, inclusion: { in: %w(daily weekly), allow_blank: true }
  validate :validate_by_days

  # rubocop:disable Style/IfInsideElse
  def initialize(*)
    super

    if start_at.present?
      self.start_at = start_at.in_time_zone.try { |time| kind == "date" ? Date.demongoize(time) : DateTime.demongoize(time) }
    end
    if end_at.present?
      self.end_at = end_at.in_time_zone.try { |time| kind == "date" ? Date.demongoize(time) : DateTime.demongoize(time) }
    else
      if start_at.present?
        self.end_at = start_at + 1.day
      end
    end
  end
  # rubocop:enable Style/IfInsideElse

  # Converts an object of this instance into a database friendly value.
  def mongoize
    ret = { kind: kind }
    self.class.attribute_types.each do |name, type|
      value = send(name)
      next unless value

      case type.type
      when :string
        value = ::String.mongoize(value)
      when :integer
        value = ::Integer.mongoize(value)
      when :datetime
        value = ::DateTime.mongoize(value)
      end

      ret[name] = value
    end
    ret
  end

  class << self
    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return nil if object.nil? || !object.is_a?(Hash)

      object = object.stringify_keys
      if object.key?("in_update_from_view")
        object = convert_from_view_params(object)
        return nil if object.blank?
      end

      ret = new(object.slice(*attribute_names))
      return nil unless ret.valid?

      ret
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      return nil if object.nil?
      case object
      when self
        object.mongoize
      when Hash
        demongoize(object).mongoize
      else
        object
      end
    end

    def normalize_by_days(by_days)
      Array(by_days).select(&:numeric?).map(&:to_i)
    end

    def normalize_exclude_dates(exclude_dates)
      exclude_dates.split(",").select(&:present?).map(&:in_time_zone).map(&:to_date)
    end

    private

    # rubocop:disable Style/IfInsideElse
    def convert_from_view_params(object)
      return if object["in_start_on"].blank?

      ret = {}

      ret["kind"] = object["in_kind"]
      if ret["kind"] == "date"
        ret["start_at"] = object["in_start_on"]
      else
        ret["start_at"] = "#{object["in_start_on"]} #{object["in_start_time"]}" if object["in_start_time"].present?
      end
      if ret["kind"] == "date"
        # end_on は start_on から自動で計算されるので未セットとする
        # ret["end_on"] = object["in_start_on"]
      else
        ret["end_at"] = "#{object["in_start_on"]} #{object["in_end_time"]}" if object["in_end_time"].present?
      end
      ret["frequency"] = object["in_frequency"] if object["in_frequency"].present?
      ret["until_on"] = object["in_until_on"] if object["in_until_on"].present?
      if object["in_by_days"].present?
        ret["by_days"] = normalize_by_days(object["in_by_days"])
      end
      if object["in_exclude_dates"].present?
        ret["exclude_dates"] = normalize_exclude_dates(object["in_exclude_dates"])
      end

      ret
    end
  end
  # rubocop:enable Style/IfInsideElse

  liquidize do
    export :to_long_html do
      parts = [
        I18n.l(start_date, format: :zoo_m_d_a),
        I18n.t("ss.wave_dash"),
        I18n.l(until_on, format: :zoo_m_d_a),
      ]
      if kind == "datetime"
        parts << " "
        parts << I18n.l(start_datetime, format: :zoo_h_mm)
        parts << I18n.t("ss.wave_dash")
        parts << I18n.l(end_datetime, format: :zoo_h_mm)
      end
      if frequency == "weekly" && by_days.present?
        week_days = I18n.t("date.abbr_day_names")
        parts << " ("
        parts << (by_days.map { |wday| week_days[wday] }.join(","))
        parts << ")"
      end

      parts.join
    end
  end

  def collect_event_dates(excludes: true)
    case frequency
    when "daily"
      collect_daily_event_dates(excludes: excludes)
    when "weekly"
      collect_weekly_event_dates(excludes: excludes)
    else # non-recurrence
      date = start_at.to_date
      if !excludes || exclude_dates.blank? || !exclude_dates.include?(date)
        [ date ]
      else
        []
      end
    end
  end

  def start_date
    start_at.to_date
  end

  def start_datetime
    start_at.in_time_zone
  end

  def end_date
    end_at.to_date
  end

  def end_datetime
    end_at.in_time_zone
  end

  def event_within_time?(start_at, end_at)
    range1 = Range.new(start_datetime.strftime("%1H%M").to_i, end_datetime.strftime("%1H%M").to_i, true)
    range2 = Range.new(start_at.strftime("%1H%M").to_i, end_at.strftime("%1H%M").to_i, true)
    return false if !range1.cover?(range2) && !range2.cover?(range1)
    return false if excluded_date?(start_at.to_date)
    return true if frequency != "weekly"
    by_days.include?(start_at.wday)
  end

  def included_date?(date)
    return true if exclude_dates.blank?
    return false if exclude_dates.include?(date)
    true
  end

  def excluded_date?(date)
    !included_date?(date)
  end

  private

  def validate_by_days
    return if by_days.blank?

    # normalize
    self.by_days = by_days.select(&:numeric?).map(&:to_i).sort

    # rubocop:disable Style/YodaCondition
    unless by_days.all? { |by_day| 0 <= by_day && by_day <= 6 }
      errors.add :by_days, :invalid
    end
    # rubocop:enable Style/YodaCondition
  end

  def collect_daily_event_dates(excludes:)
    date = start_date
    to = until_on.try(:to_date) || date + TERM_LIMIT
    ret = []
    loop do
      ret << date if !excludes || included_date?(date)
      date += 1.day
      break if date > to
    end
    ret
  end

  def collect_weekly_event_dates(excludes:)
    from = start_date
    to = until_on || from + TERM_LIMIT

    ret = []
    date = from
    while date <= to
      if by_days.present? && by_days.include?(date.wday) && (!excludes || included_date?(date))
        ret << date
      end
      date += 1.day
    end
    ret
  end
end
