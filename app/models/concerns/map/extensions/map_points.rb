# coding: utf-8
class Map::Extensions::MapPoints < Array
  def mongoize
    self.to_a
  end

  class << self
    def mongoize(object)
      case object
      when self.class then object.mongoize
      when Array then
        object.select { |point| point[:loc].present? }.
          each { |point| point[:loc] = SS::Extensions::Array.mongoize(point[:loc]).map{|latlng| latlng.to_f} }
      else object
        []
      end
    end
  end
end
