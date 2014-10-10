module Category::Part
  class Base
    include Cms::Part::Model

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Part::Model
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "category/node") }
  end
end
