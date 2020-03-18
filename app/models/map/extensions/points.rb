class Map::Extensions::Points < Array
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
        ary = ary.map do |point|
          point.deep_stringify_keys
        end
        ary = ary.map do |point|
          point["loc"] = Map::Extensions::Loc.mongoize(point["loc"])
          lat = point["loc"][0]
          lng = point["loc"][1]
          point["loc"] = [lng, lat] if lat < lng
          point
        end
        ary = ary.select { |point| point["loc"].present? }
        self.new(ary).mongoize
      else object
      end
    end
  end
end
