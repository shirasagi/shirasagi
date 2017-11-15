class Webmail::Extensions::ImapSettings < Array
  def mongoize
    self.to_a.map(&:to_h)
  end

  class << self
    def demongoize(object)
      object = object.to_a.map { |h| Webmail::ImapSetting.new.replace(h.symbolize_keys) }
      self.new(object)
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when Array then self.new(object).mongoize
      else object
      end
    end

    def evolve(object)
      case object
      when self.class then object.mongoize
      else object
      end
    end
  end
end
