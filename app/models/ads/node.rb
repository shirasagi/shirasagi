module Ads::Node
  class Banner
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::GroupPermission

    default_scope ->{ where(route: "ads/banner") }
  end
end
