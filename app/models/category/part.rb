module Category::Part
  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^category\//) }
  end

  class Node
    include Cms::Model::Part
    include Cms::Addon::Release
    include Cms::Addon::NodeList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "category/node") }
  end
end
