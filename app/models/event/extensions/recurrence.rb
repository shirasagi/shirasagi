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
  attribute :includes_holiday, :boolean
  # 除外日
  attribute :exclude_dates

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

    # rubocop:disable Style/YodaCondition
    def normalize_by_days(by_days)
      Array(by_days).select(&:numeric?).map(&:to_i).select { |wday| 0 <= wday && wday <= 6 }.uniq
    end
    # rubocop:enable Style/YodaCondition

    def normalize_exclude_dates(exclude_dates)
      exclude_dates.split(",").select(&:present?).map(&:in_time_zone).map(&:to_date)
    end

    private

    def convert_from_view_params(object)
      return if object["in_start_on"].blank?

      ret = {}

      if object["in_start_time"].blank?
        ret["start_at"] = object["in_start_on"]
      else
        ret["start_at"] = "#{object["in_start_on"]} #{object["in_start_time"]}"
      end
      if object["in_end_time"].blank?
        # end_on は start_on から自動で計算されるので未セットとする
        # ret["end_on"] = object["in_start_on"]
      else
        ret["end_at"] = "#{object["in_start_on"]} #{object["in_end_time"]}"
      end
      ret["until_on"] = object["in_until_on"] if object["in_until_on"].present?
      if object["in_by_days"].present?
        ret["by_days"] = normalize_by_days(object["in_by_days"])
        ret["includes_holiday"] = object["in_by_days"].include?("holiday")
      end
      if object["in_exclude_dates"].present?
        ret["exclude_dates"] = normalize_exclude_dates(object["in_exclude_dates"])
      end
      ret["kind"] = object["in_start_time"].present? || object["in_end_time"].present? ? "datetime" : "date"
      ret["frequency"] = ret["by_days"].present? || ret["includes_holiday"] ? "weekly" : "daily"

      ret
    end
  end

  liquidize do
    export :to_long_html
    export :start_date
    export :start_datetime
    export :end_date
    export :end_datetime
    export as: :until_date do |_context|
      until_on || start_date
    end
    export :includes_holiday
    export :exclude_dates
    export as: :day_of_weeks do |_context|
      if frequency == "weekly" && by_days.present?
        week_days = I18n.t("date.abbr_day_names")
        by_days.map { |wday| week_days[wday] }
      end
    end
  end

  def event_dates
    @event_dates ||= collect_event_dates
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

  def all_day?
    return true if kind == "date"

    start_time = I18n.l(start_datetime, format: :zoo_h_mm)
    return false if start_time != "10:00"

    end_time = I18n.l(end_datetime, format: :zoo_h_mm)
    return false if end_time != "17:00"

    true
  end

  def start_time_between?(from_time, to_time)
    from_time = I18n.l(from_time, format: :zoo_hh_mm)
    to_time = I18n.l(to_time, format: :zoo_hh_mm)
    start_time = I18n.l(start_datetime, format: :zoo_hh_mm)

    from_time <= start_time && start_time < to_time
  end

  def included_date?(date)
    return true if exclude_dates.blank?

    date = date.in_time_zone.to_date unless date.is_a?(Date)
    return false if exclude_dates.include?(date)

    true
  end

  def excluded_date?(date)
    !included_date?(date)
  end

  def to_long_html
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
      next if excludes && excluded_date?(date)

      ret << date
    ensure
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
    loop do
      next if excludes && excluded_date?(date)

      if by_days.present? && by_days.include?(date.wday)
        ret << date
      end
      if includes_holiday && date.national_holiday?
        ret << date
      end
    ensure
      date += 1.day
      break if  date > to
    end
    ret
  end
end
