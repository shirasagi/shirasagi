class SS::Extensions::Words < Array
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
      when self.class
        object.mongoize
      when String
        self.new(object.gsub(/[, 　、\r\n]+/, ",").split(",").select(&:present?).uniq).mongoize
      else
        object
      end
    end

    def evolve(object)
      case object
      when self.class
        object.mongoize
      else
        object
      end
    end
  end
end
