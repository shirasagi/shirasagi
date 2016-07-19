class Map::Extensions::Loc < Array
  def to_s
    join(", ")
  end

  def lat
    self[0]
  end

  def lng
    self[1]
  end

  # convert to mongoid native type
  def mongoize
    self.to_a
  end

  class << self
    # convert mongoid native type to its custom type(this class)
    def demongoize(object)
      self.new(object.to_a)
    end

    # convert any possible object to mongoid native type
    def mongoize(object)
      case object
      when self then
        object.mongoize
      when String then
        object = object.gsub(/[, 　、\r\n]+/, ",").split(",").select(&:present?)
        self[Float(object[0]), Float(object[1])].mongoize rescue []
      when Array then
        self[Float(object[0]), Float(object[1])].mongoize rescue []
      when Hash then
        lat = object[:lat].presence || object['lat']
        lng = object[:lng].presence || object['lng']
        self[Float(lat), Float(lng)].mongoize rescue []
      else
        # unknown type
        object
      end
    end

    # convert the object which was supplied to a criteria, and convert it to mongoid-friendly type
    def evolve(object)
      case object
      when self then
        object.mongoize
      else
        # unknown type
        object
      end
    end
  end
end
