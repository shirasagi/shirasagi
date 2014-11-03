module Ads::Node
  class Banner
    include Cms::Node::Model
    include Ads::Addon::BannerSetting

    default_scope ->{ where(route: "ads/banner") }
  end
end
