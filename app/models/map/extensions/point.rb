class Map::Extensions::Point < Hash
  # convert to mongoid native type
  def mongoize
    loc = self.loc
    return {} if loc.nil?

    ret = { 'loc' => loc.mongoize }
    ret['zoom_level'] = self[:zoom_level] if self[:zoom_level].present?
    ret
  end

  def loc
    value = self[:loc]
    return nil if value.nil?

    unless value.is_a?(Map::Extensions::Loc)
      self[:loc] = value = Map::Extensions::Loc.demongoize(value)
    end
    value
  end

  def zoom_level
    self[:zoom_level]
  end

  def empty?
    return true if super
    loc.empty?
  end
  alias blank? empty?

  class << self
    # convert mongoid native type to its custom type(this class)
    def demongoize(object)
      return self.new if object.nil?
      self[object.to_h.symbolize_keys]
    end

    # convert any possible object to mongoid native type
    def mongoize(object)
      case object
      when self then
        object.mongoize
      when Hash then
        loc = object[:loc].presence || object['loc'].presence
        return self.new.mongoize if loc.blank?

        ret = self[loc: Map::Extensions::Loc.mongoize(loc)]
        zoom_level = object[:zoom_level].presence || object['zoom_level'].presence
        zoom_level = Integer(zoom_level) rescue nil if zoom_level.present?
        ret[:zoom_level] = zoom_level if zoom_level.present?
        ret.mongoize
      else object
        object
      end
    end

    # convert the object which was supplied to a criteria, and convert it to mongoid-friendly type
    def evolve(object)
      mongoize(object)
    end
  end
end
