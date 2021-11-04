class Cms::Extensions::AdditionalInfo < Array
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
      when self.class
        object.mongoize
      when Array
        object.select { |ary| ary[:field].present? }
      else
        object
      end
    end
  end
end
