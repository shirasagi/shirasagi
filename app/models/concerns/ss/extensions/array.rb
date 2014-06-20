# coding: utf-8
class SS::Extensions::Array < Array
  class << self
    def mongoize(object)
      case object
      when self.class then object.mongoize
      when String then self.new(object.gsub(/[, 　、\r\n]+/, ",").split(",").compact.uniq).mongoize
      else object
        object.delete("")
        object.compact.uniq
      end
    end
  end
end
