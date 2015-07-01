class SS::Extensions::Sizes < Array
  def to_s
    join(", ")
  end

  def mongoize
    self.to_a
  end

  class << self
    def demongoize(object)
      self.new(object.to_a)
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when String then
        object = object.gsub(/[, 　、\r\n]+/, ",").split(",").select(&:present?)
        object = [Integer(object[0]), Integer(object[1])] rescue []
        self.new(object).mongoize
      when Array then
        [Integer(object[0]), Integer(object[1])] rescue []
      else object
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
