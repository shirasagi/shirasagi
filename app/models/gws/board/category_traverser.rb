class Gws::Board::CategoryTraverser
  include Gws::Category::Traversable

  self.model_class = Gws::Board::Category
end
