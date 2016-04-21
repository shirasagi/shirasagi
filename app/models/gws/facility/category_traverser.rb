class Gws::Facility::CategoryTraverser
  include Gws::Category::Traversable

  self.model_class = Gws::Facility::Category
end
