class Cms::Extensions::HtmlAttributes < String
  def to_h
    self.to_s.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  class << self
    def demongoize(object)
      return nil if object.nil?
      self.new object
    end
  end
end
