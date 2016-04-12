class Gws::Share::CategoryTraverser
  include Gws::Category::Traversable

  self.model_class = Gws::Share::Category
end
