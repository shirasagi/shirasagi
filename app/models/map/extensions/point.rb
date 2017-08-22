class Map::Extensions::Point < Hash
  # convert to mongoid native type
  def mongoize
    loc = self.loc
    return {} if loc.nil?

    ret = { "loc" => loc.mongoize }
    ret["zoom_level"] = zoom_level if zoom_level.present?
    ret
  end

  def loc
    value = self["loc"].presence || self[:loc]
    return nil if value.nil?

    unless value.is_a?(Map::Extensions::Loc)
      value = Map::Extensions::Loc.demongoize(value)
    end
    value
  end

  def zoom_level
    self["zoom_level"].presence || self[:zoom_level]
  end

  def empty?
    return true if super
    loc.blank?
  end
  alias blank? empty?

  class << self
    # convert mongoid native type to its custom type(this class)
    def demongoize(object)
      return self.new if object.nil?
      ret = self.new
      ret.merge!(object.to_h)
      ret
    end

    # convert any possible object to mongoid native type
    def mongoize(object)
      case object
      when self then
        object.mongoize
      when Hash then
        object.deep_stringify_keys!
        return self.new.mongoize if object["loc"].blank?

        object["loc"] = Map::Extensions::Loc.mongoize(object["loc"])
        if object["zoom_level"].present?
          object["zoom_level"] = Integer(object["zoom_level"]) rescue nil
        end
        ret = self.new
        ret.merge!(object)
        ret.mongoize
      else object
      end
    end

    # convert the object which was supplied to a criteria, and convert it to mongoid-friendly type
    def evolve(object)
      mongoize(object)
    end
  end
end
