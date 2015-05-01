class Map::Extensions::Loc < Array
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
        self.new(object.gsub(/[, 　、\r\n]+/, ",").split(",").compact.uniq.map(&:to_f)).mongoize
      when Array then
        object.map(&:to_f)
      else object
        object
      end
    end
  end
end
