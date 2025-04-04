class Map::Extensions::Point < Hash
  include SS::Liquidization

  liquidize do
    export :name
    export :loc
    export :text
    export :zoom_level
    export :image
  end

  def []=(key, value)
    if key.to_s == "name" || key.to_s == "text"
      value = sanitize(value)
      validate_script_tags(value, key) if value.present?
    end
    super
  end

  def sanitize(value)
    return nil if value.nil?
    value.to_s.gsub(/<[^>]*>/, '')
  end

  def validate_script_tags(value, key)
    if value =~ /<script/i
      errors.add(key, I18n.t("errors.messages.script_not_allowed"))
    end
  end

  # convert to mongoid native type
  def mongoize
    loc = self.loc
    return {} if loc.nil?

    ret = { "loc" => loc.mongoize }
    ret["name"] = sanitize(name) if name.present?
    ret["text"] = sanitize(text) if text.present?
    ret["zoom_level"] = zoom_level if zoom_level.present?
    ret
  end

  def name
    value = self["name"].presence || self[:name]
    return nil if value.nil?
    sanitize(value)
  end

  def loc
    value = self["loc"].presence || self[:loc]
    return nil if value.nil?

    unless value.is_a?(Map::Extensions::Loc)
      value = Map::Extensions::Loc.demongoize(value)
    end
    value
  end

  def text
    value = self["text"].presence || self[:text]
    return nil if value.nil?
    sanitize(value)
  end

  def zoom_level
    self["zoom_level"].presence || self[:zoom_level]
  end

  def image
    self["image"].presence || self[:image]
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
      when self
        object.mongoize
      when Hash
        h = object.deep_stringify_keys
        return self.new.mongoize if h["loc"].blank?

        h["loc"] = Map::Extensions::Loc.mongoize(h["loc"])
        if h["zoom_level"].present?
          h["zoom_level"] = Integer(h["zoom_level"]) rescue nil
        end
        ret = self.new
        ret.merge!(h)
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
