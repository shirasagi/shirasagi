class SS::Extensions::ArrayOfHash < Array
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
      when Array then
        ary = object.dup
        ary = ary.map { |v| v.deep_stringify_keys }
        ary = ary.compact
        self.new(ary).mongoize
      else object
      end
    end
  end
end
