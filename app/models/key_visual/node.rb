module KeyVisual::Node
  class Image
    include Cms::Model::Node
    include Cms::Addon::GroupPermission

    default_scope ->{ where(route: "key_visual/image") }
  end
end
