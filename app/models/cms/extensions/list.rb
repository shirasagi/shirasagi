class Cms::Extensions::List < Array
  def mongoize
    self.to_a
  end

  class << self
    def demongoize(object)
      if object.present?
        object.map { |h| h.symbolize_keys }
      else
        []
      end
    end

    def mongoize(object)
      case object
      when self.class then object.mongoize
      when Array then
        object.select { |ary| ary[:text].present? }
      else
        object
      end
    end
  end
end
