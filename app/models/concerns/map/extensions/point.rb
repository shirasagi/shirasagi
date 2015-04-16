class Map::Extensions::Point < Hash
  def mongoize
    self.to_h
  end

  class << self
    def demongoize(object)
      self.new.merge(object.to_h).symbolize_keys
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when Hash then
        object[:loc] = Map::Extensions::Loc.mongoize(object[:loc])
        object[:zoom_level] = object[:zoom_level].to_i if object[:zoom_level].present?
        object = object[:loc].present? ? object : nil
        self.new.merge(object.to_h).symbolize_keys.mongoize
      else object
        object
      end
    end
  end
end
