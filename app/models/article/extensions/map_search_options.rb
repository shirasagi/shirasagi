class Article::Extensions::MapSearchOptions < Array
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
        ary = object.dup
        ary = ary.map { |v| v.deep_stringify_keys }
        ary = ary.map do |options|
          name = options['name']
          values = options['values'].to_s.split(/\R/).compact
          (name.present? && values.present?) ? { name: name, values: values } : nil
        end.compact
        self.new(ary).mongoize
      else object
      end
    end
  end
end
