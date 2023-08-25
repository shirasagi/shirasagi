module Gws::Addon::Notice::Calendar
  extend ActiveSupport::Concern
  extend SS::Addon
  include Gws::Schedule::Colorize

  included do
    field :start_on, type: Date
    field :end_on, type: Date
    field :color, type: String
    permit_params :start_on, :end_on, :color

    alias_method :start_at, :start_on
    alias_method :end_at, :end_on

    validates :start_on, datetime: true, presence: true, if: -> { end_on }
    validates :end_on, datetime: true, presence: true, if: -> { start_on }
    validate :validate_start_end
    validate :validate_color

    scope :between_dates, ->(target_start, target_end) {
      where :end_on.gte => target_start, :start_on.lte => target_end
    }
  end

  def term_enabled?
    start_on && end_on
  end

  def allday?
    true
  end

  def calendar_format(user, site)
    start_at_to_format = start_on.in_time_zone
    end_at_to_format = end_on.in_time_zone.end_of_day.change(usec: 0)

    data = { id: id.to_s, start: start_at_to_format, end: end_at_to_format, allDay: allday? }

    #data[:readable] = allowed?(:read, user, site: site)
    data[:readable] = readable?(user, site: site)
    data[:editable] = false

    data[:title] = name
    data[:abbrTitle] = name.truncate(20)

    data[:startDateLabel] = date_label(start_at_to_format)
    data[:endDateLabel] = date_label(end_at_to_format)

    # allways allday
    data[:allDayLabel] = ""
    data[:className] = 'fc-event-range'
    data[:backgroundColor] = color if color.present?
    data[:textColor] = text_color if color.present?
    data[:start] = start_at_to_format.to_date
    data[:end] = (end_at_to_format + 1.day).to_date
    data[:className] += ' fc-event-allday'

    #if categories.present?
    #  data[:className] += " fc-event-category"
    #  data[:categories] = categories.map do |cate|
    #    color = "#e8e8e8"
    #    text_color = "#444"
    #
    #    color = cate.color if cate.color.present?
    #    text_color = cate.text_color if cate.text_color.present?
    #
    #    { name: cate.name, color: color, text_color: text_color }
    #  end
    #end

    data
  end

  def date_label(datetime)
    I18n.l(datetime.to_date, format: :gws_long)
  end

  private

  def validate_start_end
    if start_on && end_on && start_on > end_on
      errors.add :end_on, :greater_than, count: t(:start_on)
    end
  end

  def validate_color
    self.color = nil if color && color.match?(/^#ffffff$/i)
  end

  module ClassMethods
    def exists_term
      self.where(start_on: { "$exists" => true }, end_on: { "$exists" => true })
    end
  end
end
