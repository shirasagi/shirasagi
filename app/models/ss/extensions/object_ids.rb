class SS::Extensions::ObjectIds < Array
  def mongoize
    self.to_a
  end

  class << self
    # Get the object as it was stored in the database, and instantiate
    # this custom class from it.
    def demongoize(object)
      self.new(object.to_a)
    end

    # Takes any possible object and converts it to how it would be
    # stored in the database.
    def mongoize(object)
      case object
      when nil
        nil
      when self.class
        object.mongoize
      when Array
        mongoize_array(object)
      else
        mongoize_array(Array.wrap(object))
      end
    end

    # Converts the object that was supplied to a criteria and converts it
    # into a database friendly form.
    def evolve(object)
      case object
      when self.class
        object.mongoize
      else
        object
      end
    end

    private

    def mongoize_array(array)
      ids = array.flatten.reject(&:blank?)
      ids.uniq!
      ids.map! do |id|
        id = id.to_s
        if id.numeric? && !BSON::ObjectId.legal?(id)
          id.to_i
        else
          id
        end
      end

      new(ids).mongoize
    end
  end
end
