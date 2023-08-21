class Event::Extensions::EventDates < Array
  class << self
    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      return if object.nil?

      case object
      when Event::Extensions::EventDates
        object
      when Array
        new(object.select { |item| item.respond_to?(:in_time_zone) }.map(&:in_time_zone).compact.map(&:to_date))
      when Time, Date, DateTime, String
        new([ object.in_time_zone.to_date ])
      else
        raise "not supported event_dates"
      end
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case object
      when String
        mongoize_string(object)
      when Array
        mongoize_array(object)
      else
        nil
      end
    end

    # # Converts the object that was supplied to a criteria and converts it
    # # into a database friendly form.
    # def evolve(object)
    #   mongoize(object)
    # end

    private

    def mongoize_string(object)
      mongoize_array(object.split(/\R+/))
    end

    def mongoize_array(array)
      array = array.filter_map { |item| item.in_time_zone if item.respond_to?(:in_time_zone) }.map(&:to_date)
      array.compact!
      array.uniq!
      array.sort!

      new(array)
    end
  end

  def clustered
    Event.cluster_dates(self)
  end
end
