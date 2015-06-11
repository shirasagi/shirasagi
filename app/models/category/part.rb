module Category::Part
  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Model::Part
    include Cms::Addon::NodeList

    default_scope ->{ where(route: "category/node") }
  end
end
