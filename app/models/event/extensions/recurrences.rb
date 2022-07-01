class Event::Extensions::Recurrences
  include ActiveModel::Model
  extend Forwardable
  include Enumerable

  def_delegators :values, :[], :[]=, :length, :size, :each, :sort_by, :count, :find, :find_index, :select, :reject,
    :map, :group_by, :all?, :any?, :each_with_index, :reverse_each, :each_slice, :take, :drop, :to_a,
    :empty?, :present?, :blank?

  attr_accessor :values

  # Converts an object of this instance into a database friendly value.
  def mongoize
    return if values.blank?
    values.map { |value| value.mongoize }
  end

  def collect_event_dates
    values.map { |recurrence| recurrence.collect_event_dates }.flatten.uniq.sort
  end

  def start_time_between(from_time, to_time)
    values.select { |recurrence| recurrence.start_time_between?(from_time, to_time) }
  end

  def start_time_between?(from_time, to_time)
    values.any? { |recurrence| recurrence.start_time_between?(from_time, to_time) }
  end

  class << self
    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return new(values: []) if object.nil?
      values = object.map do |value|
        case value
        when Event::Extensions::Recurrence
          value
        when Hash
          Event::Extensions::Recurrence.demongoize(value)
        end
      end
      values.compact!
      new(values: values)
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      return nil if object.nil?
      case object
      when self
        object.mongoize
      when Array
        demongoize(object).mongoize
      else
        object
      end
    end
  end
end
