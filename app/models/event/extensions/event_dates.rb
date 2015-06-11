class Event::Extensions::EventDates < Array
  def mongoize
    self.to_a
  end

  class << self
    def demongoize(object)
      if object.present?
        String.new(object.map { |d| d.strftime("%Y/%m/%d") }.join("\r\n"))
      else
        String.new("")
      end
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when String then
        set = object.split(/\r\n|\n/).map do |d|
          begin
            Date.parse(d).mongoize
          rescue => e
            nil
          end
        end

        if set.present?
          set = set.compact.uniq.sort
          self.new(set).mongoize
        else
          self.new([]).mongoize
        end
      else
        object
      end
    end

    def evolve(object)
      case object
      when self.class then object.mongoize
      else
        object
      end
    end
  end
end
