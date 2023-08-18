module Category
  class Initializer
    Cms::Node.plugin "category/node"
    Cms::Node.plugin "category/page"
    Cms::Part.plugin "category/node"
  end
end
