class SS::Extensions::ObjectIds < Array
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
      when String then []
      when Array
        ids = object.reject {|m| m.blank? }.uniq.map {|m| m =~ /[a-z]/ ? m.to_s : m.to_i }
        #ids = object.reject {|m| m.blank? }.uniq.map {|m| BSON::ObjectId.from_string(m) }
        self.new(ids).mongoize
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
