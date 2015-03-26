class Rdf::Builders::BaseBuilder
  include Context

  def call(predicate, objects)
    if handler = handlers[predicate]
      handler.context = self
      handler.call(predicate, objects)
      return true
    end
    if name = aliases[predicate]
      handler = handlers[name]
      handler.context = self
      handler.call(predicate, objects)
      return true
    end
    nil
  end

  def build(hash)
    hash.each do |predicate, objects|
      call(predicate, objects)
    end
  end
end
