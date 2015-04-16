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
        object = object.gsub(/[, 　、\r\n]+/, ",").split(",").select(&:present?)
        object = [Float(object[0]), Float(object[1])] rescue []
        self.new(object).mongoize
      when Array then
        [Float(object[0]), Float(object[1])] rescue []
      else object
        object
      end
    end
  end
end
