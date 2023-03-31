module KeyVisual::Node
  class Image
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::GroupPermission
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "key_visual/image") }
  end
end
