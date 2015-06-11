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
        object = object.each do |point|
          point[:loc] = Map::Extensions::Loc.mongoize(point[:loc])
          point[:zoom_level] = point[:zoom_level].to_i if point[:zoom_level].present?
        end
        object = object.select { |point| point[:loc].present? }
        self.new(object).mongoize
      else object
        object
      end
    end
  end
end
