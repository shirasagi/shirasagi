module Ads::Node
  class Banner
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "ads/banner") }
  end
end
